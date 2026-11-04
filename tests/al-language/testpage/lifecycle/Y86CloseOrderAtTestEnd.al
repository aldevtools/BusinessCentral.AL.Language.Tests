// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 94596, pages 94597-94598, codeunit 94599 (log, used by this test codeunit only), test codeunit 94600
// Probe (writer Y86, al-runtime-rs assumption test-end-close-order): two or three local TestPages (and a global one) still open when the test procedure
// ends: in which order do their OnQueryClosePage and OnClosePage run: order of declaration, order of opening, reverse? Y47CloseAtTestEnd.al pins
// one page. Each "left open" test is followed by a test that reads the SingleInstance log (tests of one codeunit run in declaration order).
// BC versions: 27, 28, 29

codeunit 94599 "LT Y86 CO Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Add(Line: Text)
    begin
        Lines += Line + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Lines;
        Lines := '';
        exit(Result);
    end;
}

page 94597 "LT Y86 CO Card A"
{
    PageType = Card;
    SourceTable = "ALT Shape 07";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y86 CO Log";
    begin
        Log.Add('queryclose A ' + Rec."Code");
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y86 CO Log";
    begin
        Log.Add('close A ' + Rec."Code");
    end;
}

page 94598 "LT Y86 CO Card B"
{
    PageType = Card;
    SourceTable = "ALT Shape 07";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Log: Codeunit "LT Y86 CO Log";
    begin
        Log.Add('queryclose B ' + Rec."Code");
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT Y86 CO Log";
    begin
        Log.Add('close B ' + Rec."Code");
    end;
}

codeunit 94600 "LT Y86 Close Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        GlobalA: TestPage "LT Y86 CO Card A";

    local procedure Seed()
    var
        Row: Record "ALT Shape 07";
    begin
        Row.DeleteAll();
        Row."Code" := 'R1';
        Row.Insert();
        Row."Code" := 'R2';
        Row.Insert();
        Row."Code" := 'R3';
        Row.Insert();
    end;

    local procedure GoTo(var Row: Record "ALT Shape 07"; RowCode: Code[10])
    begin
        Row.Get(RowCode);
    end;

    [Test]
    procedure Y86_T01_DeclaredAThenB_OpenedBThenA()
    var
        Row: Record "ALT Shape 07";
        PageA: TestPage "LT Y86 CO Card A";
        PageB: TestPage "LT Y86 CO Card B";
        Log: Codeunit "LT Y86 CO Log";
    begin
        Log.Take();
        Seed();
        PageB.OpenEdit();
        GoTo(Row, 'R2');
        PageB.GoToRecord(Row);
        PageA.OpenEdit();
        GoTo(Row, 'R1');
        PageA.GoToRecord(Row);
        Log.Add('end');
    end;

    [Test]
    procedure Y86_T02_ReadLog_AThenB_OpenedBThenA()
    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT Y86 CO Log";
    begin
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'end;queryclose B R2;close B R2;queryclose A R1;close A R1;');
        Obs.Verify();
    end;

    [Test]
    procedure Y86_T03_DeclaredBThenA_OpenedBThenA()
    var
        Row: Record "ALT Shape 07";
        PageB: TestPage "LT Y86 CO Card B";
        PageA: TestPage "LT Y86 CO Card A";
        Log: Codeunit "LT Y86 CO Log";
    begin
        Log.Take();
        Seed();
        PageB.OpenEdit();
        GoTo(Row, 'R2');
        PageB.GoToRecord(Row);
        PageA.OpenEdit();
        GoTo(Row, 'R1');
        PageA.GoToRecord(Row);
        Log.Add('end');
    end;

    [Test]
    procedure Y86_T04_ReadLog_BThenA_OpenedBThenA()
    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT Y86 CO Log";
    begin
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'end;queryclose A R1;close A R1;queryclose B R2;close B R2;');
        Obs.Verify();
    end;

    [Test]
    procedure Y86_T05_SamePageTwice_OpenedSecondFirst()
    var
        Row: Record "ALT Shape 07";
        First: TestPage "LT Y86 CO Card A";
        Second: TestPage "LT Y86 CO Card A";
        Log: Codeunit "LT Y86 CO Log";
    begin
        Log.Take();
        Seed();
        Second.OpenEdit();
        GoTo(Row, 'R3');
        Second.GoToRecord(Row);
        First.OpenEdit();
        GoTo(Row, 'R1');
        First.GoToRecord(Row);
        Log.Add('end');
    end;

    [Test]
    procedure Y86_T06_ReadLog_SamePageTwice()
    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT Y86 CO Log";
    begin
        Obs.Observe('log', Log.Take());
        Obs.Expect('log', 'end;queryclose A R3;close A R3;queryclose A R1;close A R1;');
        Obs.Verify();
    end;

    [Test]
    procedure Y86_T07_GlobalAndLocal_LocalOpenedFirst()
    var
        Row: Record "ALT Shape 07";
        PageB: TestPage "LT Y86 CO Card B";
        Log: Codeunit "LT Y86 CO Log";
    begin
        Log.Take();
        Seed();
        PageB.OpenEdit();
        GoTo(Row, 'R2');
        PageB.GoToRecord(Row);
        GlobalA.OpenEdit();
        GoTo(Row, 'R1');
        GlobalA.GoToRecord(Row);
        Log.Add('end');
    end;

    [Test]
    procedure Y86_T08_ReadLog_GlobalAndLocal()
    var
        Obs: Codeunit "Probe Observer";
        Log: Codeunit "LT Y86 CO Log";
    begin
        Obs.Observe('log', Log.Take());
        GlobalA.Close();
        Obs.Observe('log after closing the global', Log.Take());
        Obs.Expect('log', 'end;queryclose B R2;close B R2;');
        Obs.Expect('log after closing the global', 'queryclose A R1;close A R1;');
        Obs.Verify();
    end;
}
