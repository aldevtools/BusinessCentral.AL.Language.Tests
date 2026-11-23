// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97273-97278 (LT NB ...)
// Probe: from al-runner issue 6924 (waldo, test ParseMetaTagChangeType): the first member of an enum is NAMED (None) and its caption is blank, not named " " (that shape is pinned in
//   EvalLanguageBoolean.al, WA_BlankEnum1/2/3). The test writes Format(member) into a JSON text and reads it back with Evaluate under another GlobalLanguage, and Evaluate accepts
//   the text on BC. Four shapes, each under GlobalLanguage 1034, 2067 and 1033: an Enum with value(0; None) { Caption = ' '; }, one with CaptionML = ENU = ' ', ESP = ' ', NLB = ' ',
//   one with value(0; None) { Caption = ''; }, and an Option field with OptionMembers = None,First,Second and OptionCaption = ' ,First cap,Second cap'. For each: Format of the
//   first member (and with format 9 and 2), a JSON text round trip of it, and Evaluate of that text, of an empty text, one and two blanks, the member name, the captions and the
//   ordinal. The start value is Second, so a value that is kept shows.
// Facts: see the Expect lines (measured by the corpus CI matrix).
// BC versions: 27+ (tested by the corpus CI matrix)

enum 97273 "LT NB Caption Space Enum"
{
    Extensible = true;

    value(0; None) { Caption = ' '; }
    value(1; First) { Caption = 'First cap'; }
    value(2; Second) { Caption = 'Second cap'; }
}

enum 97274 "LT NB CaptionML Space Enum"
{
    Extensible = true;

    value(0; None) { CaptionML = ENU = ' ', ESP = ' ', NLB = ' '; }
    value(1; First) { CaptionML = ENU = 'First cap', ESP = 'Primero', NLB = 'Eerste BE'; }
    value(2; Second) { CaptionML = ENU = 'Second cap', ESP = 'Segundo', NLB = 'Tweede BE'; }
}

enum 97275 "LT NB Caption Empty Enum"
{
    Extensible = true;

    value(0; None) { Caption = ''; }
    value(1; First) { Caption = 'First cap'; }
    value(2; Second) { Caption = 'Second cap'; }
}

table 97276 "LT NB Option Row"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option)
        {
            OptionMembers = None,First,Second;
            OptionCaption = ' ,First cap,Second cap';
        }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 97277 "LT NB Evaluate"
{
    Subtype = Test;

    local procedure Words(Blank: Text): List of [Text]
    var
        WordList: List of [Text];
    begin
        WordList.Add(Blank);
        WordList.AddRange('', ' ', '  ', 'None', 'none', 'First', 'Primero', 'First cap', 'Eerste BE', '0');
        exit(WordList);
    end;

    local procedure Roundtrip(Text: Text): Text
    var
        Obj: JsonObject;
        Tok: JsonToken;
    begin
        Obj.Add('Type', Text);
        Obj.Get('Type', Tok);
        exit(Tok.AsValue().AsText());
    end;

    local procedure NB_Space(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        E: Enum "LT NB Caption Space Enum";
        Blank: Enum "LT NB Caption Space Enum";
        Word: Text;
        Ok: Boolean;
    begin
        GlobalLanguage(Lang);
        Observer.Observe('Format blank', '[' + Format(Blank) + ']');
        Observer.Observe('Format blank 0 9', '[' + Format(Blank, 0, 9) + ']');
        Observer.Observe('Format blank 0 2', '[' + Format(Blank, 0, 2) + ']');
        foreach Word in Words(Roundtrip(Format(Blank))) do begin
            E := E::Second;
            ClearLastError();
            Ok := Evaluate(E, Word);
            if Ok then
                Observer.Observe('Evaluate [' + Word + ']', 'ok|' + Format(E, 0, 2) + '|[' + Format(E) + ']')
            else begin
                Observer.Observe('Evaluate [' + Word + ']', 'rejected|' + Format(E, 0, 2));
                Observer.ObserveError('Evaluate [' + Word + ']');
            end;
        end;
        E := E::Second;
        Ok := Evaluate(E, Format(Blank), 9);
        Observer.Observe('Evaluate format 9 of blank', Format(Ok) + '|' + Format(E, 0, 2));
        E := E::Second;
        Evaluate(E, Roundtrip(Format(Blank)));
        Observer.Observe('Evaluate statement of the round trip', Format(E, 0, 2));
        GlobalLanguage(1033);
    end;

    local procedure NB_CaptionML(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        E: Enum "LT NB CaptionML Space Enum";
        Blank: Enum "LT NB CaptionML Space Enum";
        Word: Text;
        Ok: Boolean;
    begin
        GlobalLanguage(Lang);
        Observer.Observe('Format blank', '[' + Format(Blank) + ']');
        Observer.Observe('Format blank 0 9', '[' + Format(Blank, 0, 9) + ']');
        Observer.Observe('Format blank 0 2', '[' + Format(Blank, 0, 2) + ']');
        foreach Word in Words(Roundtrip(Format(Blank))) do begin
            E := E::Second;
            ClearLastError();
            Ok := Evaluate(E, Word);
            if Ok then
                Observer.Observe('Evaluate [' + Word + ']', 'ok|' + Format(E, 0, 2) + '|[' + Format(E) + ']')
            else begin
                Observer.Observe('Evaluate [' + Word + ']', 'rejected|' + Format(E, 0, 2));
                Observer.ObserveError('Evaluate [' + Word + ']');
            end;
        end;
        E := E::Second;
        Ok := Evaluate(E, Format(Blank), 9);
        Observer.Observe('Evaluate format 9 of blank', Format(Ok) + '|' + Format(E, 0, 2));
        E := E::Second;
        Evaluate(E, Roundtrip(Format(Blank)));
        Observer.Observe('Evaluate statement of the round trip', Format(E, 0, 2));
        GlobalLanguage(1033);
    end;

    local procedure NB_Empty(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        E: Enum "LT NB Caption Empty Enum";
        Blank: Enum "LT NB Caption Empty Enum";
        Word: Text;
        Ok: Boolean;
    begin
        GlobalLanguage(Lang);
        Observer.Observe('Format blank', '[' + Format(Blank) + ']');
        Observer.Observe('Format blank 0 9', '[' + Format(Blank, 0, 9) + ']');
        Observer.Observe('Format blank 0 2', '[' + Format(Blank, 0, 2) + ']');
        foreach Word in Words(Roundtrip(Format(Blank))) do begin
            E := E::Second;
            ClearLastError();
            Ok := Evaluate(E, Word);
            if Ok then
                Observer.Observe('Evaluate [' + Word + ']', 'ok|' + Format(E, 0, 2) + '|[' + Format(E) + ']')
            else begin
                Observer.Observe('Evaluate [' + Word + ']', 'rejected|' + Format(E, 0, 2));
                Observer.ObserveError('Evaluate [' + Word + ']');
            end;
        end;
        E := E::Second;
        Ok := Evaluate(E, Format(Blank), 9);
        Observer.Observe('Evaluate format 9 of blank', Format(Ok) + '|' + Format(E, 0, 2));
        GlobalLanguage(1033);
    end;

    local procedure NB_Option(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Row: Record "LT NB Option Row" temporary;
        Blank: Record "LT NB Option Row" temporary;
        Word: Text;
        Ok: Boolean;
    begin
        GlobalLanguage(Lang);
        Observer.Observe('Format blank', '[' + Format(Blank.Kind) + ']');
        Observer.Observe('Format blank 0 9', '[' + Format(Blank.Kind, 0, 9) + ']');
        Observer.Observe('Format blank 0 2', '[' + Format(Blank.Kind, 0, 2) + ']');
        foreach Word in Words(Roundtrip(Format(Blank.Kind))) do begin
            Row.Kind := Row.Kind::Second;
            ClearLastError();
            Ok := Evaluate(Row.Kind, Word);
            if Ok then
                Observer.Observe('Evaluate [' + Word + ']', 'ok|' + Format(Row.Kind, 0, 2) + '|[' + Format(Row.Kind) + ']')
            else begin
                Observer.Observe('Evaluate [' + Word + ']', 'rejected|' + Format(Row.Kind, 0, 2));
                Observer.ObserveError('Evaluate [' + Word + ']');
            end;
        end;
        Row.Kind := Row.Kind::Second;
        Ok := Evaluate(Row.Kind, Format(Blank.Kind), 9);
        Observer.Observe('Evaluate format 9 of blank', Format(Ok) + '|' + Format(Row.Kind, 0, 2));
        GlobalLanguage(1033);
    end;

    [Test]
    procedure NB_Space_ES_1034()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Space(Observer, 1034);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Sí|0');
        Observer.Expect('Evaluate statement of the round trip', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_Space_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Space(Observer, 2067);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Ja|0');
        Observer.Expect('Evaluate statement of the round trip', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_Space_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Space(Observer, 1033);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Yes|0');
        Observer.Expect('Evaluate statement of the round trip', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_CaptionML_ES_1034()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_CaptionML(Observer, 1034);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[Primero]');
        Observer.Expect('Evaluate [Primero]', 'ok|1|[Primero]');
        Observer.Expect('Evaluate [First cap]', 'rejected|2');
        Observer.Expect('Evaluate [First cap]|text', '');
        Observer.Expect('Evaluate [First cap]|code', '');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Sí|0');
        Observer.Expect('Evaluate statement of the round trip', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_CaptionML_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_CaptionML(Observer, 2067);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[Eerste BE]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'rejected|2');
        Observer.Expect('Evaluate [First cap]|text', '');
        Observer.Expect('Evaluate [First cap]|code', '');
        Observer.Expect('Evaluate [Eerste BE]', 'ok|1|[Eerste BE]');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Ja|0');
        Observer.Expect('Evaluate statement of the round trip', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_CaptionML_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_CaptionML(Observer, 1033);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Yes|0');
        Observer.Expect('Evaluate statement of the round trip', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_Empty_ES_1034()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Empty(Observer, 1034);
        Observer.Expect('Format blank', '[0]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate []', 'ok|0|[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [None]', 'ok|0|[0]');
        Observer.Expect('Evaluate [none]', 'ok|0|[0]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate format 9 of blank', 'Sí|0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_Empty_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Empty(Observer, 2067);
        Observer.Expect('Format blank', '[0]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate []', 'ok|0|[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [None]', 'ok|0|[0]');
        Observer.Expect('Evaluate [none]', 'ok|0|[0]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate format 9 of blank', 'Ja|0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_Empty_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Empty(Observer, 1033);
        Observer.Expect('Format blank', '[0]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate []', 'ok|0|[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [None]', 'ok|0|[0]');
        Observer.Expect('Evaluate [none]', 'ok|0|[0]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate format 9 of blank', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_Option_ES_1034()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Option(Observer, 1034);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Sí|0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_Option_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Option(Observer, 2067);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Ja|0');
        Observer.Verify();
    end;

    [Test]
    procedure NB_Option_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NB_Option(Observer, 1033);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [None]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [none]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Yes|0');
        Observer.Verify();
    end;
}
