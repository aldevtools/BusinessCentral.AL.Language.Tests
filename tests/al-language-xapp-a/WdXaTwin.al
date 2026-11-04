// Objects of cross-app fixture A (writer WD). Test: tests/al-language/pageext/lt-wd/WdPageExtInternalTwin.al.
//   61130 / 61131 / 61132: a log, a table and a page with a public and a protected procedure; the page's own code calls both. Fixture B's page extension
//   declares internal procedures with the same names and parameter types (al-runner issue 6294, follow-up to 6043).

table 61130 "LT WD XA Entry"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 61131 "LT WD XA Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Step: Text)
    begin
        if Log <> '' then
            Log += ';';
        Log += Step;
    end;

    procedure Get(): Text
    begin
        exit(Log);
    end;

    procedure Reset()
    begin
        Log := '';
    end;
}

page 61132 "LT WD XA Apply"
{
    PageType = List;
    SourceTable = "LT WD XA Entry";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("No."; Rec."No.") { }
            }
        }
    }

    procedure CalcAmount()
    begin
        CheckRounding();
        CheckProtected();
    end;

    procedure CheckRounding()
    var
        Log: Codeunit "LT WD XA Log";
    begin
        Log.Add('base public');
    end;

    protected procedure CheckProtected()
    var
        Log: Codeunit "LT WD XA Log";
    begin
        Log.Add('base protected');
    end;
}
