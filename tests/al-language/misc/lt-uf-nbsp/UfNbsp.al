// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-language-reference
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 90335, test codeunit 90336, helper codeunit 90337
// Probe (outside issue 6152): NO-BREAK SPACE (U+00A0) as whitespace outside comments and strings. alc accepts it like U+0020. This file uses U+00A0 as indentation of
//   statements, of object-level lines (field, keys, procedure header, var section) and of a blank line, between tokens (around `:=`, after `begin`, before `;`), after `//`
//   and as trailing whitespace; and inside a string literal (kept as one character, not folded to a space). The bytes are C2 A0 (UTF-8). Keep them: an editor that
//   normalizes whitespace changes the test (check `grep -c $'\xc2\xa0' <file>` after an edit).
// BC versions: 27-29

table 90335 "LT UF Nbsp Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 90336 "LT UF Nbsp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure NbspIndentation()
    var
        Observer: Codeunit "Probe Observer";
        Total: Integer;
        Txt: Text;
    begin
        // a comment indented with U+00A0 and with it inside
        Total := 1;
        Total := Total + 41;
        Total := Total ;
        Observer.Observe('total', Format(Total));
        Txt := 'a b';
        Observer.Observe('string length', Format(StrLen(Txt)));
        Observer.Observe('string char code', Format(Txt[2]) = ' ' ? 'space' : 'other');
        Observer.Observe('string equals space form', Format(Txt = 'a b'));
        if Total = 42 then 
            Observer.Observe('if', 'taken')
        else
            Observer.Observe('if', 'not taken');
        Observer.Finish();
    end;

    [Test]
    procedure NbspBetweenTokens()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UF Nbsp Row";
    begin Row.DeleteAll();
        Row.Init();
        Row.Id := 5;
        Row.Name := 'five';
        Row.Insert();
        Row.Get(5);
        Observer.Observe('name', Row.Name);
        Observer.Observe('count', Format(Row.Count()));
        Observer.Finish();
    end;

    [Test]
    procedure OtherUnicodeSpaceSeparators()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT UF Nbsp Zs";
    begin
        Observer.Observe('EmSpace', Format(Helper.EmSpace(20)));
        Observer.Observe('IdeographicSpace', Format(Helper.IdeographicSpace(20)));
        Observer.Observe('NarrowNbsp', Format(Helper.NarrowNbsp(20)));
        Observer.Observe('ThinSpace', Format(Helper.ThinSpace(20)));
        Observer.Observe('EnSpace', Format(Helper.EnSpace(20)));
        Observer.Observe('FigureSpace', Format(Helper.FigureSpace(20)));
        Observer.Observe('OghamSpaceMark', Format(Helper.OghamSpaceMark(20)));
        Observer.Finish();
    end;
}

// Helper: each procedure is written with another Unicode space separator (category Zs) as indentation and between tokens.
codeunit 90337 "LT UF Nbsp Zs"
{

    procedure EmSpace(Start: Integer): Integer
    var
    Result: Integer;
    begin
    Result := Start + 2;
    exit(Result);
    end;

    procedure IdeographicSpace(Start: Integer): Integer
    var
　　　　Result: Integer;
    begin
　　　　Result　:=　Start　+　2;
　　　　exit(Result);
    end;

    procedure NarrowNbsp(Start: Integer): Integer
    var
    Result: Integer;
    begin
    Result := Start + 2;
    exit(Result);
    end;

    procedure ThinSpace(Start: Integer): Integer
    var
    Result: Integer;
    begin
    Result := Start + 2;
    exit(Result);
    end;

    procedure EnSpace(Start: Integer): Integer
    var
    Result: Integer;
    begin
    Result := Start + 2;
    exit(Result);
    end;

    procedure FigureSpace(Start: Integer): Integer
    var
    Result: Integer;
    begin
    Result := Start + 2;
    exit(Result);
    end;

    procedure OghamSpaceMark(Start: Integer): Integer
    var
    Result: Integer;
    begin
    Result := Start + 2;
    exit(Result);
    end;
}
