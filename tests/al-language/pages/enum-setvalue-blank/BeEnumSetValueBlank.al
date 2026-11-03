// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enums 81150-81152, table 81150, page 81150, codeunit 81150, test codeunit 81160
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: TestPage field SetValue on an Enum control whose value 0 is " " with Caption = ' ' (a space), as on page 113 "Budget"
//   (control GLAccCategory shows a page variable of Enum "G/L Account Category"; Microsoft's ERM Budget tests 134922/134927 call SetValue(0)).
//   Controls: a table field and a page variable, each for an enum with AssignmentCompatibility = true (like enum 15), an enum without it, an enum
//   whose value 0 has a normal caption ('Zero'), and an Option with OptionCaption ' ,Alpha,Beta' for comparison.
//   Inputs: Integer 0, 1, 2, 5; Text ' ', '', '1', 'Alpha'; the value-0 member itself. Each input reaches SetValue in four ways, which BC
//   treats differently: through a Variant parameter of a helper, a Text variable, an Integer variable, or a literal written in the SetValue call.
//   Each input runs on a freshly opened page (start = value 0) and after SetValue of a Text variable 'Beta' (start = value 2). Per input: whether SetValue raised and its error text/code, the control's Value afterwards,
//   the ordinals the control's OnValidate saw (log), and for a field control the stored ordinal after Close.
// Measured (BC 27.5, 28.5, 29.0): an Integer (variable, literal or in a Variant) selects the value by ordinal on every control, so SetValue(0)
//   selects " " and the control shows ' '; an ordinal that is not a value fails with 'Your entry of '<old ordinal>' is not an acceptable value'.
//   A Text variable or literal goes by caption: ' ' selects the value whose caption is ' ' (Enum and Option), '' and '1' are refused; on the
//   Enum whose value 0 has the caption 'Zero', ' ' is refused too. A Text inside a Variant parameter goes by ordinal digits ('1' selects Alpha) and
//   other text fails to evaluate; that error text differs on BC 27 (see the #if blocks). AssignmentCompatibility makes no difference.
// Corpus issue: StefanMaron/BusinessCentral.AL.Language.Tests#660 item 1.
// BC versions: all (CI)

enum 81150 "LT BE Blank Enum Compat"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; Alpha) { Caption = 'Alpha'; }
    value(2; Beta) { Caption = 'Beta'; }
}

enum 81151 "LT BE Blank Enum Strict"
{
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; Alpha) { Caption = 'Alpha'; }
    value(2; Beta) { Caption = 'Beta'; }
}

enum 81152 "LT BE Plain Enum"
{
    Extensible = false;

    value(0; Zero) { Caption = 'Zero'; }
    value(1; Alpha) { Caption = 'Alpha'; }
    value(2; Beta) { Caption = 'Beta'; }
}

table 81150 "LT BE Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ECompat; Enum "LT BE Blank Enum Compat") { }
        field(3; EStrict; Enum "LT BE Blank Enum Strict") { }
        field(4; EPlain; Enum "LT BE Plain Enum") { }
        field(5; Opt; Option) { OptionMembers = " ",Alpha,Beta; OptionCaption = ' ,Alpha,Beta'; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 81150 "LT BE Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

page 81150 "LT BE Enum Card"
{
    PageType = Card;
    SourceTable = "LT BE Enum Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(FCompat; Rec.ECompat)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add(Format(Rec.ECompat.AsInteger()));
                end;
            }
            field(FStrict; Rec.EStrict)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add(Format(Rec.EStrict.AsInteger()));
                end;
            }
            field(FPlain; Rec.EPlain)
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Log.Add(Format(Rec.EPlain.AsInteger()));
                end;
            }
            field(FOpt; Rec.Opt)
            {
                ApplicationArea = All;
                trigger OnValidate()
                var
                    N: Integer;
                begin
                    N := Rec.Opt;
                    Log.Add(Format(N));
                end;
            }
            field(VCompat; VarCompat)
            {
                ApplicationArea = All;
                Caption = 'Compat Filter';
                trigger OnValidate()
                begin
                    Log.Add(Format(VarCompat.AsInteger()));
                end;
            }
            field(VStrict; VarStrict)
            {
                ApplicationArea = All;
                Caption = 'Strict Filter';
                trigger OnValidate()
                begin
                    Log.Add(Format(VarStrict.AsInteger()));
                end;
            }
            field(VPlain; VarPlain)
            {
                ApplicationArea = All;
                Caption = 'Plain Filter';
                trigger OnValidate()
                begin
                    Log.Add(Format(VarPlain.AsInteger()));
                end;
            }
            field(VOpt; VarOpt)
            {
                ApplicationArea = All;
                Caption = 'Option Filter';
                OptionCaption = ' ,Alpha,Beta';
                trigger OnValidate()
                var
                    N: Integer;
                begin
                    N := VarOpt;
                    Log.Add(Format(N));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT BE Log";
        VarCompat: Enum "LT BE Blank Enum Compat";
        VarStrict: Enum "LT BE Blank Enum Strict";
        VarPlain: Enum "LT BE Plain Enum";
        VarOpt: Option " ",Alpha,Beta;
}

codeunit 81160 "LT BE Enum SetValue Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT BE Log";

    local procedure Seed()
    var
        Row: Record "LT BE Enum Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
    end;

    local procedure StoredOrdinal(Ctl: Text): Text
    var
        Row: Record "LT BE Enum Row";
        N: Integer;
    begin
        Row.Get(1);
        case Ctl of
            'FCompat':
                exit(Format(Row.ECompat.AsInteger()));
            'FStrict':
                exit(Format(Row.EStrict.AsInteger()));
            'FPlain':
                exit(Format(Row.EPlain.AsInteger()));
            'FOpt':
                begin
                    N := Row.Opt;
                    exit(Format(N));
                end;
        end;
        exit('n/a');
    end;

    [TryFunction]
    local procedure TrySetVariant(var TP: TestPage "LT BE Enum Card"; Ctl: Text; Input: Variant)
    begin
        case Ctl of
            'FCompat':
                TP.FCompat.SetValue(Input);
            'FStrict':
                TP.FStrict.SetValue(Input);
            'FPlain':
                TP.FPlain.SetValue(Input);
            'FOpt':
                TP.FOpt.SetValue(Input);
            'VCompat':
                TP.VCompat.SetValue(Input);
            'VStrict':
                TP.VStrict.SetValue(Input);
            'VPlain':
                TP.VPlain.SetValue(Input);
            'VOpt':
                TP.VOpt.SetValue(Input);
        end;
    end;

    [TryFunction]
    local procedure TrySetText(var TP: TestPage "LT BE Enum Card"; Ctl: Text; Input: Text)
    begin
        case Ctl of
            'FCompat':
                TP.FCompat.SetValue(Input);
            'FStrict':
                TP.FStrict.SetValue(Input);
            'FPlain':
                TP.FPlain.SetValue(Input);
            'FOpt':
                TP.FOpt.SetValue(Input);
            'VCompat':
                TP.VCompat.SetValue(Input);
            'VStrict':
                TP.VStrict.SetValue(Input);
            'VPlain':
                TP.VPlain.SetValue(Input);
            'VOpt':
                TP.VOpt.SetValue(Input);
        end;
    end;

    [TryFunction]
    local procedure TrySetInt(var TP: TestPage "LT BE Enum Card"; Ctl: Text; Input: Integer)
    begin
        case Ctl of
            'FCompat':
                TP.FCompat.SetValue(Input);
            'FStrict':
                TP.FStrict.SetValue(Input);
            'FPlain':
                TP.FPlain.SetValue(Input);
            'FOpt':
                TP.FOpt.SetValue(Input);
            'VCompat':
                TP.VCompat.SetValue(Input);
            'VStrict':
                TP.VStrict.SetValue(Input);
            'VPlain':
                TP.VPlain.SetValue(Input);
            'VOpt':
                TP.VOpt.SetValue(Input);
        end;
    end;

    [TryFunction]
    local procedure TrySetLiteral(var TP: TestPage "LT BE Enum Card"; Ctl: Text; LitTag: Text)
    begin
        case Ctl of
            'FCompat':
                case LitTag of
                    'lit0':
                        TP.FCompat.SetValue(0);
                    'lit1':
                        TP.FCompat.SetValue(1);
                    'lit5':
                        TP.FCompat.SetValue(5);
                    'litSpace':
                        TP.FCompat.SetValue(' ');
                    'litEmpty':
                        TP.FCompat.SetValue('');
                    'litAlpha':
                        TP.FCompat.SetValue('Alpha');
                    'litDigit1':
                        TP.FCompat.SetValue('1');
                end;
            'FStrict':
                case LitTag of
                    'lit0':
                        TP.FStrict.SetValue(0);
                    'lit1':
                        TP.FStrict.SetValue(1);
                    'lit5':
                        TP.FStrict.SetValue(5);
                    'litSpace':
                        TP.FStrict.SetValue(' ');
                    'litEmpty':
                        TP.FStrict.SetValue('');
                    'litAlpha':
                        TP.FStrict.SetValue('Alpha');
                    'litDigit1':
                        TP.FStrict.SetValue('1');
                end;
            'FPlain':
                case LitTag of
                    'lit0':
                        TP.FPlain.SetValue(0);
                    'lit1':
                        TP.FPlain.SetValue(1);
                    'lit5':
                        TP.FPlain.SetValue(5);
                    'litSpace':
                        TP.FPlain.SetValue(' ');
                    'litEmpty':
                        TP.FPlain.SetValue('');
                    'litAlpha':
                        TP.FPlain.SetValue('Alpha');
                    'litDigit1':
                        TP.FPlain.SetValue('1');
                end;
            'FOpt':
                case LitTag of
                    'lit0':
                        TP.FOpt.SetValue(0);
                    'lit1':
                        TP.FOpt.SetValue(1);
                    'lit5':
                        TP.FOpt.SetValue(5);
                    'litSpace':
                        TP.FOpt.SetValue(' ');
                    'litEmpty':
                        TP.FOpt.SetValue('');
                    'litAlpha':
                        TP.FOpt.SetValue('Alpha');
                    'litDigit1':
                        TP.FOpt.SetValue('1');
                end;
            'VCompat':
                case LitTag of
                    'lit0':
                        TP.VCompat.SetValue(0);
                    'lit1':
                        TP.VCompat.SetValue(1);
                    'lit5':
                        TP.VCompat.SetValue(5);
                    'litSpace':
                        TP.VCompat.SetValue(' ');
                    'litEmpty':
                        TP.VCompat.SetValue('');
                    'litAlpha':
                        TP.VCompat.SetValue('Alpha');
                    'litDigit1':
                        TP.VCompat.SetValue('1');
                end;
            'VStrict':
                case LitTag of
                    'lit0':
                        TP.VStrict.SetValue(0);
                    'lit1':
                        TP.VStrict.SetValue(1);
                    'lit5':
                        TP.VStrict.SetValue(5);
                    'litSpace':
                        TP.VStrict.SetValue(' ');
                    'litEmpty':
                        TP.VStrict.SetValue('');
                    'litAlpha':
                        TP.VStrict.SetValue('Alpha');
                    'litDigit1':
                        TP.VStrict.SetValue('1');
                end;
            'VPlain':
                case LitTag of
                    'lit0':
                        TP.VPlain.SetValue(0);
                    'lit1':
                        TP.VPlain.SetValue(1);
                    'lit5':
                        TP.VPlain.SetValue(5);
                    'litSpace':
                        TP.VPlain.SetValue(' ');
                    'litEmpty':
                        TP.VPlain.SetValue('');
                    'litAlpha':
                        TP.VPlain.SetValue('Alpha');
                    'litDigit1':
                        TP.VPlain.SetValue('1');
                end;
            'VOpt':
                case LitTag of
                    'lit0':
                        TP.VOpt.SetValue(0);
                    'lit1':
                        TP.VOpt.SetValue(1);
                    'lit5':
                        TP.VOpt.SetValue(5);
                    'litSpace':
                        TP.VOpt.SetValue(' ');
                    'litEmpty':
                        TP.VOpt.SetValue('');
                    'litAlpha':
                        TP.VOpt.SetValue('Alpha');
                    'litDigit1':
                        TP.VOpt.SetValue('1');
                end;
        end;
    end;

    local procedure ValueOf(var TP: TestPage "LT BE Enum Card"; Ctl: Text): Text
    begin
        case Ctl of
            'FCompat':
                exit(TP.FCompat.Value());
            'FStrict':
                exit(TP.FStrict.Value());
            'FPlain':
                exit(TP.FPlain.Value());
            'FOpt':
                exit(TP.FOpt.Value());
            'VCompat':
                exit(TP.VCompat.Value());
            'VStrict':
                exit(TP.VStrict.Value());
            'VPlain':
                exit(TP.VPlain.Value());
            'VOpt':
                exit(TP.VOpt.Value());
        end;
    end;

    [TryFunction]
    local procedure TryClose(var TP: TestPage "LT BE Enum Card")
    begin
        TP.Close();
    end;

    // One input on a freshly opened page. FromBeta first sets the control to 'Beta' through a Text variable. Mode says how the input
    // reaches SetValue: V = a Variant parameter, T = a Text variable, I = an Integer variable, L = a literal written in the call (LitTag).
    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Ctl: Text; FromBeta: Boolean; Tag: Text; Mode: Text; V: Variant; T: Text; I: Integer; LitTag: Text)
    var
        TP: TestPage "LT BE Enum Card";
        Ok: Boolean;
    begin
        Seed();
        TP.OpenEdit();
        if FromBeta then begin
            if not TrySetText(TP, Ctl, 'Beta') then
                Observer.ObserveError(Tag + '-startBeta');
            Observer.Observe(Tag + '-start', '[' + ValueOf(TP, Ctl) + ']');
            Log.Take();
        end;
        case Mode of
            'V':
                Ok := TrySetVariant(TP, Ctl, V);
            'T':
                Ok := TrySetText(TP, Ctl, T);
            'I':
                Ok := TrySetInt(TP, Ctl, I);
            'L':
                Ok := TrySetLiteral(TP, Ctl, LitTag);
        end;
        Observer.Observe(Tag, Format(Ok));
        if not Ok then
            Observer.ObserveError(Tag + '-err');
        Observer.Observe(Tag + '-value', '[' + ValueOf(TP, Ctl) + ']');
        Observer.Observe(Tag + '-log', '[' + Log.Take() + ']');
        if not TryClose(TP) then
            Observer.ObserveError(Tag + '-close');
        if CopyStr(Ctl, 1, 1) = 'F' then
            Observer.Observe(Tag + '-stored', StoredOrdinal(Ctl));
    end;

    [Test]
    procedure SetValue_FCompat_VariantInts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', false, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'FCompat', false, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'FCompat', false, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'FCompat', false, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int2-stored', '2');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''0'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_VariantTexts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', false, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'FCompat', false, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'FCompat', false, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'FCompat', false, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'FCompat', false, 'member0', 'V', "LT BE Blank Enum Compat"::" ", '', 0, '');
#if BC28PLUS
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '0');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '0');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_FCompat_TextVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', false, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'FCompat', false, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'FCompat', false, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'FCompat', false, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of '''' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[0]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''1'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[0]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('digit1-stored', '0');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Expect('capAlpha-stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_IntVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', false, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'FCompat', false, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'FCompat', false, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''0'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_IntLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', false, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'FCompat', false, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'FCompat', false, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit0-stored', '0');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit1-stored', '1');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''0'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[0]');
        Observer.Expect('lit5-log', '[]');
        Observer.Expect('lit5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_TextLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', false, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'FCompat', false, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'FCompat', false, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'FCompat', false, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litSpace-stored', '0');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of '''' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[0]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litEmpty-stored', '0');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litAlpha-stored', '1');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''1'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[0]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Expect('litDigit1-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_VariantInts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', true, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'FCompat', true, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'FCompat', true, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'FCompat', true, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int2-start', '[Beta]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int2-stored', '2');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''2'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_VariantTexts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', true, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'FCompat', true, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'FCompat', true, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'FCompat', true, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'FCompat', true, 'member0', 'V', "LT BE Blank Enum Compat"::" ", '', 0, '');
#if BC28PLUS
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '2');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '2');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '2');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '2');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '2');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '2');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_FCompat_TextVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', true, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'FCompat', true, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'FCompat', true, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'FCompat', true, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of '''' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[2]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''1'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[2]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('digit1-stored', '0');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Expect('capAlpha-stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_IntVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', true, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'FCompat', true, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'FCompat', true, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''2'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_IntLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', true, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'FCompat', true, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'FCompat', true, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0-start', '[Beta]');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit0-stored', '0');
        Observer.Expect('lit1-start', '[Beta]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit1-stored', '1');
        Observer.Expect('lit5-start', '[Beta]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''2'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[2]');
        Observer.Expect('lit5-log', '[]');
        Observer.Expect('lit5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FCompat_TextLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FCompat', true, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'FCompat', true, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'FCompat', true, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'FCompat', true, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace-start', '[Beta]');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litSpace-stored', '0');
        Observer.Expect('litEmpty-start', '[Beta]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of '''' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[2]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litEmpty-stored', '0');
        Observer.Expect('litAlpha-start', '[Beta]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litAlpha-stored', '1');
        Observer.Expect('litDigit1-start', '[Beta]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: FCompat,  Message = ''Your entry of ''1'' is not an acceptable value for ''ECompat''. (Select Refresh to discard errors)''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[2]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Expect('litDigit1-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_VariantInts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', false, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'FStrict', false, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'FStrict', false, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'FStrict', false, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int2-stored', '2');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''0'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_VariantTexts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', false, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'FStrict', false, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'FStrict', false, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'FStrict', false, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'FStrict', false, 'member0', 'V', "LT BE Blank Enum Strict"::" ", '', 0, '');
#if BC28PLUS
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '0');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '0');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_FStrict_TextVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', false, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'FStrict', false, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'FStrict', false, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'FStrict', false, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of '''' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[0]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''1'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[0]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('digit1-stored', '0');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Expect('capAlpha-stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_IntVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', false, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'FStrict', false, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'FStrict', false, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''0'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_IntLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', false, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'FStrict', false, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'FStrict', false, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit0-stored', '0');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit1-stored', '1');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''0'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[0]');
        Observer.Expect('lit5-log', '[]');
        Observer.Expect('lit5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_TextLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', false, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'FStrict', false, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'FStrict', false, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'FStrict', false, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litSpace-stored', '0');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of '''' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[0]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litEmpty-stored', '0');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litAlpha-stored', '1');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''1'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[0]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Expect('litDigit1-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_VariantInts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', true, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'FStrict', true, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'FStrict', true, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'FStrict', true, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int2-start', '[Beta]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int2-stored', '2');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''2'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_VariantTexts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', true, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'FStrict', true, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'FStrict', true, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'FStrict', true, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'FStrict', true, 'member0', 'V', "LT BE Blank Enum Strict"::" ", '', 0, '');
#if BC28PLUS
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '2');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '2');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '2');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '2');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '2');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '2');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_FStrict_TextVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', true, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'FStrict', true, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'FStrict', true, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'FStrict', true, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of '''' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[2]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''1'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[2]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('digit1-stored', '0');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Expect('capAlpha-stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_IntVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', true, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'FStrict', true, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'FStrict', true, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''2'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_IntLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', true, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'FStrict', true, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'FStrict', true, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0-start', '[Beta]');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit0-stored', '0');
        Observer.Expect('lit1-start', '[Beta]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit1-stored', '1');
        Observer.Expect('lit5-start', '[Beta]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''2'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[2]');
        Observer.Expect('lit5-log', '[]');
        Observer.Expect('lit5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FStrict_TextLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FStrict', true, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'FStrict', true, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'FStrict', true, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'FStrict', true, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace-start', '[Beta]');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litSpace-stored', '0');
        Observer.Expect('litEmpty-start', '[Beta]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of '''' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[2]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litEmpty-stored', '0');
        Observer.Expect('litAlpha-start', '[Beta]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litAlpha-stored', '1');
        Observer.Expect('litDigit1-start', '[Beta]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: FStrict,  Message = ''Your entry of ''1'' is not an acceptable value for ''EStrict''. (Select Refresh to discard errors)''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[2]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Expect('litDigit1-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_VariantInts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', false, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'FPlain', false, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'FPlain', false, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'FPlain', false, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[Zero]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int2-stored', '2');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''0'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_VariantTexts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', false, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'FPlain', false, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'FPlain', false, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'FPlain', false, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'FPlain', false, 'member0', 'V', "LT BE Plain Enum"::Zero, '', 0, '');
#if BC28PLUS
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Zero]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Zero]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Zero]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '0');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[Zero]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Zero]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Zero]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Zero]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '0');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[Zero]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_FPlain_TextVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', false, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'FPlain', false, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'FPlain', false, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'FPlain', false, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of '' '' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('space-err|code', 'TestValidation');
        Observer.Expect('space-value', '[0]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of '''' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[0]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''1'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[0]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('digit1-stored', '0');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Expect('capAlpha-stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_IntVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', false, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'FPlain', false, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'FPlain', false, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[Zero]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''0'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_IntLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', false, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'FPlain', false, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'FPlain', false, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[Zero]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit0-stored', '0');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit1-stored', '1');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''0'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[0]');
        Observer.Expect('lit5-log', '[]');
        Observer.Expect('lit5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_TextLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', false, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'FPlain', false, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'FPlain', false, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'FPlain', false, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace', 'No');
        Observer.Expect('litSpace-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of '' '' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('litSpace-err|code', 'TestValidation');
        Observer.Expect('litSpace-value', '[0]');
        Observer.Expect('litSpace-log', '[]');
        Observer.Expect('litSpace-stored', '0');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of '''' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[0]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litEmpty-stored', '0');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litAlpha-stored', '1');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''1'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[0]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Expect('litDigit1-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_VariantInts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', true, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'FPlain', true, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'FPlain', true, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'FPlain', true, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[Zero]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int2-start', '[Beta]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int2-stored', '2');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''2'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_VariantTexts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', true, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'FPlain', true, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'FPlain', true, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'FPlain', true, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'FPlain', true, 'member0', 'V', "LT BE Plain Enum"::Zero, '', 0, '');
#if BC28PLUS
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '2');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '2');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '2');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[Zero]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '2');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '2');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '2');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[Zero]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_FPlain_TextVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', true, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'FPlain', true, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'FPlain', true, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'FPlain', true, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of '' '' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('space-err|code', 'TestValidation');
        Observer.Expect('space-value', '[2]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of '''' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[2]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''1'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[2]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('digit1-stored', '0');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Expect('capAlpha-stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_IntVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', true, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'FPlain', true, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'FPlain', true, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[Zero]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''2'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_IntLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', true, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'FPlain', true, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'FPlain', true, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0-start', '[Beta]');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[Zero]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit0-stored', '0');
        Observer.Expect('lit1-start', '[Beta]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit1-stored', '1');
        Observer.Expect('lit5-start', '[Beta]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''2'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[2]');
        Observer.Expect('lit5-log', '[]');
        Observer.Expect('lit5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FPlain_TextLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'FPlain', true, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'FPlain', true, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'FPlain', true, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'FPlain', true, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace-start', '[Beta]');
        Observer.Expect('litSpace', 'No');
        Observer.Expect('litSpace-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of '' '' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('litSpace-err|code', 'TestValidation');
        Observer.Expect('litSpace-value', '[2]');
        Observer.Expect('litSpace-log', '[]');
        Observer.Expect('litSpace-stored', '0');
        Observer.Expect('litEmpty-start', '[Beta]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of '''' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[2]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litEmpty-stored', '0');
        Observer.Expect('litAlpha-start', '[Beta]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litAlpha-stored', '1');
        Observer.Expect('litDigit1-start', '[Beta]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: FPlain,  Message = ''Your entry of ''1'' is not an acceptable value for ''EPlain''. (Select Refresh to discard errors)''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[2]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Expect('litDigit1-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_VariantInts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', false, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'FOpt', false, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'FOpt', false, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'FOpt', false, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int2-stored', '2');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''0'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_VariantTexts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', false, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'FOpt', false, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'FOpt', false, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'FOpt', false, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'FOpt', false, 'member0', 'V', OptZero, '', 0, '');
#if BC28PLUS
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '0');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '0');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_FOpt_TextVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', false, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'FOpt', false, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'FOpt', false, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'FOpt', false, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of '''' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[0]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[0]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('digit1-stored', '0');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Expect('capAlpha-stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_IntVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', false, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'FOpt', false, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'FOpt', false, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''0'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_IntLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', false, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'FOpt', false, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'FOpt', false, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit0-stored', '0');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit1-stored', '1');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''0'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[0]');
        Observer.Expect('lit5-log', '[]');
        Observer.Expect('lit5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_TextLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', false, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'FOpt', false, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'FOpt', false, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'FOpt', false, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litSpace-stored', '0');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of '''' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[0]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litEmpty-stored', '0');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litAlpha-stored', '1');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[0]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Expect('litDigit1-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_VariantInts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', true, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'FOpt', true, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'FOpt', true, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'FOpt', true, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int2-start', '[Beta]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int2-stored', '2');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''2'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_VariantTexts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', true, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'FOpt', true, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'FOpt', true, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'FOpt', true, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'FOpt', true, 'member0', 'V', OptZero, '', 0, '');
#if BC28PLUS
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '2');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '2');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '2');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('space-stored', '2');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '2');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('digit1-stored', '1');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('capAlpha-stored', '2');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Expect('member0-stored', '0');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_FOpt_TextVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', true, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'FOpt', true, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'FOpt', true, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'FOpt', true, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('space-stored', '0');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of '''' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[2]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('empty-stored', '0');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[2]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('digit1-stored', '0');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Expect('capAlpha-stored', '1');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_IntVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', true, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'FOpt', true, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'FOpt', true, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int0-stored', '0');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int1-stored', '1');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''2'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Expect('int5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_IntLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', true, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'FOpt', true, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'FOpt', true, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0-start', '[Beta]');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit0-stored', '0');
        Observer.Expect('lit1-start', '[Beta]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit1-stored', '1');
        Observer.Expect('lit5-start', '[Beta]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''2'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[2]');
        Observer.Expect('lit5-log', '[]');
        Observer.Expect('lit5-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_FOpt_TextLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'FOpt', true, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'FOpt', true, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'FOpt', true, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'FOpt', true, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace-start', '[Beta]');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litSpace-stored', '0');
        Observer.Expect('litEmpty-start', '[Beta]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of '''' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[2]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litEmpty-stored', '0');
        Observer.Expect('litAlpha-start', '[Beta]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litAlpha-stored', '1');
        Observer.Expect('litDigit1-start', '[Beta]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: FOpt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Opt''. (Select Refresh to discard errors)''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[2]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Expect('litDigit1-stored', '0');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_VariantInts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', false, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'VCompat', false, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'VCompat', false, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'VCompat', false, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''0'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_VariantTexts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', false, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'VCompat', false, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'VCompat', false, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'VCompat', false, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'VCompat', false, 'member0', 'V', "LT BE Blank Enum Compat"::" ", '', 0, '');
#if BC28PLUS
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_VCompat_TextVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', false, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'VCompat', false, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'VCompat', false, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'VCompat', false, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of '''' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[0]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''1'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[0]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_IntVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', false, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'VCompat', false, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'VCompat', false, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''0'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_IntLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', false, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'VCompat', false, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'VCompat', false, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''0'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[0]');
        Observer.Expect('lit5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_TextLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', false, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'VCompat', false, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'VCompat', false, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'VCompat', false, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of '''' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[0]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''1'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[0]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_VariantInts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', true, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'VCompat', true, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'VCompat', true, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'VCompat', true, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int2-start', '[Beta]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''2'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_VariantTexts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', true, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'VCompat', true, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'VCompat', true, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'VCompat', true, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'VCompat', true, 'member0', 'V', "LT BE Blank Enum Compat"::" ", '', 0, '');
#if BC28PLUS
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_VCompat_TextVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', true, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'VCompat', true, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'VCompat', true, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'VCompat', true, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of '''' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[2]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''1'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[2]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_IntVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', true, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'VCompat', true, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'VCompat', true, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''2'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_IntLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', true, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'VCompat', true, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'VCompat', true, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0-start', '[Beta]');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit1-start', '[Beta]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit5-start', '[Beta]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''2'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[2]');
        Observer.Expect('lit5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VCompat_TextLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VCompat', true, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'VCompat', true, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'VCompat', true, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'VCompat', true, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace-start', '[Beta]');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litEmpty-start', '[Beta]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of '''' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[2]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litAlpha-start', '[Beta]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litDigit1-start', '[Beta]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: VCompat,  Message = ''Your entry of ''1'' is not an acceptable value for ''Compat Filter''.''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[2]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_VariantInts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', false, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'VStrict', false, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'VStrict', false, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'VStrict', false, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''0'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_VariantTexts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', false, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'VStrict', false, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'VStrict', false, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'VStrict', false, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'VStrict', false, 'member0', 'V', "LT BE Blank Enum Strict"::" ", '', 0, '');
#if BC28PLUS
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_VStrict_TextVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', false, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'VStrict', false, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'VStrict', false, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'VStrict', false, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of '''' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[0]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''1'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[0]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_IntVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', false, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'VStrict', false, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'VStrict', false, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''0'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_IntLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', false, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'VStrict', false, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'VStrict', false, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''0'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[0]');
        Observer.Expect('lit5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_TextLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', false, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'VStrict', false, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'VStrict', false, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'VStrict', false, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of '''' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[0]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''1'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[0]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_VariantInts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', true, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'VStrict', true, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'VStrict', true, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'VStrict', true, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int2-start', '[Beta]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''2'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_VariantTexts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', true, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'VStrict', true, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'VStrict', true, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'VStrict', true, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'VStrict', true, 'member0', 'V', "LT BE Blank Enum Strict"::" ", '', 0, '');
#if BC28PLUS
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_VStrict_TextVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', true, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'VStrict', true, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'VStrict', true, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'VStrict', true, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of '''' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[2]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''1'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[2]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_IntVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', true, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'VStrict', true, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'VStrict', true, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''2'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_IntLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', true, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'VStrict', true, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'VStrict', true, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0-start', '[Beta]');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit1-start', '[Beta]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit5-start', '[Beta]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''2'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[2]');
        Observer.Expect('lit5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VStrict_TextLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VStrict', true, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'VStrict', true, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'VStrict', true, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'VStrict', true, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace-start', '[Beta]');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litEmpty-start', '[Beta]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of '''' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[2]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litAlpha-start', '[Beta]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litDigit1-start', '[Beta]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: VStrict,  Message = ''Your entry of ''1'' is not an acceptable value for ''Strict Filter''.''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[2]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_VariantInts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', false, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'VPlain', false, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'VPlain', false, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'VPlain', false, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[Zero]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''0'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_VariantTexts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', false, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'VPlain', false, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'VPlain', false, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'VPlain', false, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'VPlain', false, 'member0', 'V', "LT BE Plain Enum"::Zero, '', 0, '');
#if BC28PLUS
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Zero]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Zero]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Zero]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[Zero]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Zero]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Zero]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Zero]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[Zero]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_VPlain_TextVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', false, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'VPlain', false, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'VPlain', false, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'VPlain', false, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of '' '' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('space-err|code', 'TestValidation');
        Observer.Expect('space-value', '[0]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of '''' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[0]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''1'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[0]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_IntVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', false, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'VPlain', false, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'VPlain', false, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[Zero]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''0'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_IntLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', false, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'VPlain', false, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'VPlain', false, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[Zero]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''0'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[0]');
        Observer.Expect('lit5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_TextLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', false, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'VPlain', false, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'VPlain', false, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'VPlain', false, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace', 'No');
        Observer.Expect('litSpace-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of '' '' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('litSpace-err|code', 'TestValidation');
        Observer.Expect('litSpace-value', '[0]');
        Observer.Expect('litSpace-log', '[]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of '''' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[0]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''1'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[0]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_VariantInts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', true, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'VPlain', true, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'VPlain', true, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'VPlain', true, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[Zero]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int2-start', '[Beta]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''2'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_VariantTexts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', true, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'VPlain', true, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'VPlain', true, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'VPlain', true, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'VPlain', true, 'member0', 'V', "LT BE Plain Enum"::Zero, '', 0, '');
#if BC28PLUS
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[Zero]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[Zero]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_VPlain_TextVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', true, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'VPlain', true, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'VPlain', true, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'VPlain', true, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of '' '' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('space-err|code', 'TestValidation');
        Observer.Expect('space-value', '[2]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of '''' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[2]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''1'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[2]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_IntVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', true, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'VPlain', true, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'VPlain', true, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[Zero]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''2'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_IntLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', true, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'VPlain', true, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'VPlain', true, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0-start', '[Beta]');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[Zero]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit1-start', '[Beta]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit5-start', '[Beta]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''2'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[2]');
        Observer.Expect('lit5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VPlain_TextLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunCase(Observer, 'VPlain', true, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'VPlain', true, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'VPlain', true, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'VPlain', true, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace-start', '[Beta]');
        Observer.Expect('litSpace', 'No');
        Observer.Expect('litSpace-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of '' '' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('litSpace-err|code', 'TestValidation');
        Observer.Expect('litSpace-value', '[2]');
        Observer.Expect('litSpace-log', '[]');
        Observer.Expect('litEmpty-start', '[Beta]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of '''' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[2]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litAlpha-start', '[Beta]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litDigit1-start', '[Beta]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: VPlain,  Message = ''Your entry of ''1'' is not an acceptable value for ''Plain Filter''.''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[2]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_VariantInts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', false, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'VOpt', false, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'VOpt', false, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'VOpt', false, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''0'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_VariantTexts_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', false, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'VOpt', false, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'VOpt', false, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'VOpt', false, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'VOpt', false, 'member0', 'V', OptZero, '', 0, '');
#if BC28PLUS
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[ ]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[ ]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_VOpt_TextVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', false, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'VOpt', false, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'VOpt', false, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'VOpt', false, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of '''' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[0]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[0]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_IntVars_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', false, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'VOpt', false, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'VOpt', false, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''0'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[0]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_IntLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', false, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'VOpt', false, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'VOpt', false, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''0'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[0]');
        Observer.Expect('lit5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_TextLiterals_FromBlank()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', false, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'VOpt', false, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'VOpt', false, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'VOpt', false, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of '''' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[0]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[0]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_VariantInts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', true, 'int0', 'V', 0, '', 0, '');
        RunCase(Observer, 'VOpt', true, 'int1', 'V', 1, '', 0, '');
        RunCase(Observer, 'VOpt', true, 'int2', 'V', 2, '', 0, '');
        RunCase(Observer, 'VOpt', true, 'int5', 'V', 5, '', 0, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int2-start', '[Beta]');
        Observer.Expect('int2', 'Yes');
        Observer.Expect('int2-value', '[Beta]');
        Observer.Expect('int2-log', '[2]');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''2'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_VariantTexts_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', true, 'space', 'V', ' ', '', 0, '');
        RunCase(Observer, 'VOpt', true, 'empty', 'V', '', '', 0, '');
        RunCase(Observer, 'VOpt', true, 'digit1', 'V', '1', '', 0, '');
        RunCase(Observer, 'VOpt', true, 'capAlpha', 'V', 'Alpha', '', 0, '');
        RunCase(Observer, 'VOpt', true, 'member0', 'V', OptZero, '', 0, '');
#if BC28PLUS
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The value " " can''t be evaluated into type Option.');
        Observer.Expect('space-err|code', 'Evaluate:Format');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The value "" can''t be evaluated into type Option.');
        Observer.Expect('empty-err|code', 'Evaluate:Format');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The value "Alpha" can''t be evaluated into type Option.');
        Observer.Expect('capAlpha-err|code', 'Evaluate:Format');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#else
        // BC 27.5 answers 'The type NavOption is unknown.' (code NotSupportedType) for these texts, on Linux and on Windows BC 27.5
        // (Windows check 2026-10-20); 28.5 and 29.0 give the Evaluate error asserted above.
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'No');
        Observer.Expect('space-err|text', 'The type NavOption is unknown.');
        Observer.Expect('space-err|code', 'NotSupportedType');
        Observer.Expect('space-value', '[Beta]');
        Observer.Expect('space-log', '[]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'The type NavOption is unknown.');
        Observer.Expect('empty-err|code', 'NotSupportedType');
        Observer.Expect('empty-value', '[Beta]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'Yes');
        Observer.Expect('digit1-value', '[Alpha]');
        Observer.Expect('digit1-log', '[1]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'No');
        Observer.Expect('capAlpha-err|text', 'The type NavOption is unknown.');
        Observer.Expect('capAlpha-err|code', 'NotSupportedType');
        Observer.Expect('capAlpha-value', '[Beta]');
        Observer.Expect('capAlpha-log', '[]');
        Observer.Expect('member0-start', '[Beta]');
        Observer.Expect('member0', 'Yes');
        Observer.Expect('member0-value', '[ ]');
        Observer.Expect('member0-log', '[0]');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure SetValue_VOpt_TextVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', true, 'space', 'T', 0, ' ', 0, '');
        RunCase(Observer, 'VOpt', true, 'empty', 'T', 0, '', 0, '');
        RunCase(Observer, 'VOpt', true, 'digit1', 'T', 0, '1', 0, '');
        RunCase(Observer, 'VOpt', true, 'capAlpha', 'T', 0, 'Alpha', 0, '');
        Observer.Expect('space-start', '[Beta]');
        Observer.Expect('space', 'Yes');
        Observer.Expect('space-value', '[ ]');
        Observer.Expect('space-log', '[0]');
        Observer.Expect('empty-start', '[Beta]');
        Observer.Expect('empty', 'No');
        Observer.Expect('empty-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of '''' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('empty-err|code', 'TestValidation');
        Observer.Expect('empty-value', '[2]');
        Observer.Expect('empty-log', '[]');
        Observer.Expect('digit1-start', '[Beta]');
        Observer.Expect('digit1', 'No');
        Observer.Expect('digit1-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('digit1-err|code', 'TestValidation');
        Observer.Expect('digit1-value', '[2]');
        Observer.Expect('digit1-log', '[]');
        Observer.Expect('capAlpha-start', '[Beta]');
        Observer.Expect('capAlpha', 'Yes');
        Observer.Expect('capAlpha-value', '[Alpha]');
        Observer.Expect('capAlpha-log', '[1]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_IntVars_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', true, 'int0', 'I', 0, '', 0, '');
        RunCase(Observer, 'VOpt', true, 'int1', 'I', 0, '', 1, '');
        RunCase(Observer, 'VOpt', true, 'int5', 'I', 0, '', 5, '');
        Observer.Expect('int0-start', '[Beta]');
        Observer.Expect('int0', 'Yes');
        Observer.Expect('int0-value', '[ ]');
        Observer.Expect('int0-log', '[0]');
        Observer.Expect('int1-start', '[Beta]');
        Observer.Expect('int1', 'Yes');
        Observer.Expect('int1-value', '[Alpha]');
        Observer.Expect('int1-log', '[1]');
        Observer.Expect('int5-start', '[Beta]');
        Observer.Expect('int5', 'No');
        Observer.Expect('int5-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''2'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('int5-err|code', 'TestValidation');
        Observer.Expect('int5-value', '[2]');
        Observer.Expect('int5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_IntLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', true, 'lit0', 'L', 0, '', 0, 'lit0');
        RunCase(Observer, 'VOpt', true, 'lit1', 'L', 0, '', 0, 'lit1');
        RunCase(Observer, 'VOpt', true, 'lit5', 'L', 0, '', 0, 'lit5');
        Observer.Expect('lit0-start', '[Beta]');
        Observer.Expect('lit0', 'Yes');
        Observer.Expect('lit0-value', '[ ]');
        Observer.Expect('lit0-log', '[0]');
        Observer.Expect('lit1-start', '[Beta]');
        Observer.Expect('lit1', 'Yes');
        Observer.Expect('lit1-value', '[Alpha]');
        Observer.Expect('lit1-log', '[1]');
        Observer.Expect('lit5-start', '[Beta]');
        Observer.Expect('lit5', 'No');
        Observer.Expect('lit5-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''2'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('lit5-err|code', 'TestValidation');
        Observer.Expect('lit5-value', '[2]');
        Observer.Expect('lit5-log', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure SetValue_VOpt_TextLiterals_FromBeta()
    var
        Observer: Codeunit "Probe Observer";
        OptZero: Option " ",Alpha,Beta;
    begin
        OptZero := OptZero::" ";
        RunCase(Observer, 'VOpt', true, 'litSpace', 'L', 0, '', 0, 'litSpace');
        RunCase(Observer, 'VOpt', true, 'litEmpty', 'L', 0, '', 0, 'litEmpty');
        RunCase(Observer, 'VOpt', true, 'litAlpha', 'L', 0, '', 0, 'litAlpha');
        RunCase(Observer, 'VOpt', true, 'litDigit1', 'L', 0, '', 0, 'litDigit1');
        Observer.Expect('litSpace-start', '[Beta]');
        Observer.Expect('litSpace', 'Yes');
        Observer.Expect('litSpace-value', '[ ]');
        Observer.Expect('litSpace-log', '[0]');
        Observer.Expect('litEmpty-start', '[Beta]');
        Observer.Expect('litEmpty', 'No');
        Observer.Expect('litEmpty-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of '''' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('litEmpty-err|code', 'TestValidation');
        Observer.Expect('litEmpty-value', '[2]');
        Observer.Expect('litEmpty-log', '[]');
        Observer.Expect('litAlpha-start', '[Beta]');
        Observer.Expect('litAlpha', 'Yes');
        Observer.Expect('litAlpha-value', '[Alpha]');
        Observer.Expect('litAlpha-log', '[1]');
        Observer.Expect('litDigit1-start', '[Beta]');
        Observer.Expect('litDigit1', 'No');
        Observer.Expect('litDigit1-err|text', 'Validation error for Field: VOpt,  Message = ''Your entry of ''1'' is not an acceptable value for ''Option Filter''.''');
        Observer.Expect('litDigit1-err|code', 'TestValidation');
        Observer.Expect('litDigit1-value', '[2]');
        Observer.Expect('litDigit1-log', '[]');
        Observer.Verify();
    end;

    // Writer QZ: a NotBlank Enum field set blank through SetValue on a List page (fixtures in QzNotBlankEnumList.al).
    local procedure QzSeed(): Record "LT QZ NB Row"
    var
        Row: Record "LT QZ NB Row";
    begin
        Row.DeleteAll();
        Row.Code := 'N1';
        Row.KindNB := Row.KindNB::Person;
        Row.Kind := Row.Kind::Person;
        Row.Insert();
        ClearLastError();
        exit(Row);
    end;


    [Test]
    procedure QZ_NotBlankEnum_SetValueBlank_List()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QZ NB Row";
        List: TestPage "LT QZ NB List";
    begin
        Row := QzSeed();
        List.OpenEdit();
        List.GoToRecord(Row);
        asserterror begin
            List.KindNB.SetValue('');
            Error('no error');
        end;
        Observer.ObserveError('notblank empty text');
        Observer.Observe('notblank after empty text', List.KindNB.Value());
        asserterror begin
            List.KindNB.SetValue(' ');
            Error('no error');
        end;
        Observer.ObserveError('notblank space');
        Observer.Observe('notblank after space', List.KindNB.Value());
        asserterror begin
            List.KindNB.SetValue(0);
            Error('no error');
        end;
        Observer.ObserveError('notblank ordinal 0');
        Observer.Observe('notblank after ordinal 0', List.KindNB.Value());
        asserterror begin
            List.Kind.SetValue('');
            Error('no error');
        end;
        Observer.ObserveError('plain empty text');
        Observer.Observe('plain after empty text', List.Kind.Value());
        List.Close();
        Observer.Expect('notblank empty text|text', 'Validation error for Field: KindNB,  Message = ''Your entry of '''' is not an acceptable value for ''KindNB''.''');
        Observer.Expect('notblank empty text|code', 'TestValidation');
        Observer.Expect('notblank after empty text', '1');
        Observer.Expect('notblank space|text', 'no error');
        Observer.Expect('notblank space|code', 'Dialog');
        Observer.Expect('notblank after space', ' ');
        Observer.Expect('notblank ordinal 0|text', 'no error');
        Observer.Expect('notblank ordinal 0|code', 'Dialog');
        Observer.Expect('notblank after ordinal 0', ' ');
        Observer.Expect('plain empty text|text', 'Validation error for Field: Kind,  Message = ''Your entry of '''' is not an acceptable value for ''Kind''.''');
        Observer.Expect('plain empty text|code', 'TestValidation');
        Observer.Expect('plain after empty text', '1');
        Observer.Verify();
    end;
}
