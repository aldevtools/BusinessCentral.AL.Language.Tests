// Fixture for al-runner issue 6043 (writer TI): a page of this DEPENDENCY app with a protected, a public, a local and an internal procedure of
// the same names as local procedures of the page extension in tests/al-language/pageext/lt-ext-local-same-name/ExtLocalSameNameTests.al.
// The log is used by that one test codeunit only.
codeunit 61080 "LT TI Same Name Log"
{
    SingleInstance = true;

    var
        Trail: Text;

    procedure Add(Entry: Text)
    begin
        Trail += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Trail;
        Trail := '';
        exit(Result);
    end;
}

page 61081 "LT TI Same Name Base"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    trigger OnOpenPage()
    begin
        Log.Add('base-open');
        Prot();
        Pub();
        Loc();
        Int();
    end;

    protected procedure Prot()
    begin
        Log.Add('base.Prot');
    end;

    procedure Pub()
    begin
        Log.Add('base.Pub');
    end;

    local procedure Loc()
    begin
        Log.Add('base.Loc');
    end;

    internal procedure Int()
    begin
        Log.Add('base.Int');
    end;

    procedure CallAll()
    begin
        Prot();
        Pub();
        Loc();
        Int();
    end;

    var
        Log: Codeunit "LT TI Same Name Log";
}
