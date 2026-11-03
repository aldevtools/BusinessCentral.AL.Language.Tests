// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: shared table 72313, pages 72357 and 72361, pageextension 72358, log 72362, codeunit 72363
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72362 "LT P123 Run Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 72361 "LT P123 Run Target"
{
    PageType = List;
    SourceTable = "LT P123 PRow";
    ApplicationArea = All;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
            }
        }
    }
}

page 72357 "LT P123 Run Base"
{
    PageType = List;
    SourceTable = "LT P123 PRow";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 72358 "LT P123 Run Ext" extends "LT P123 Run Base"
{
    actions
    {
        addlast(Processing)
        {
            action(ByLink)
            {
                ApplicationArea = All;
                Caption = 'By link';
                RunObject = page "LT P123 Run Target";
                RunPageLink = Id = field(Id);
            }
            action(ByView)
            {
                ApplicationArea = All;
                Caption = 'By view';
                RunObject = page "LT P123 Run Target";
                RunPageView = where(Amount = filter(>10));
            }
            action(ByMode)
            {
                ApplicationArea = All;
                Caption = 'By mode';
                RunObject = page "LT P123 Run Target";
                RunPageMode = View;
            }
        }
    }
}

codeunit 72363 "LT P123 RunPage Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P123 PRow";
    begin
        R.DeleteAll();
        R.Init(); R.Id := 1; R.Name := 'One'; R.Amount := 5; R.Insert();
        R.Init(); R.Id := 2; R.Name := 'Two'; R.Amount := 15; R.Insert();
        R.Init(); R.Id := 3; R.Name := 'Three'; R.Amount := 25; R.Insert();
    end;

    local procedure LogRows(var T: TestPage "LT P123 Run Target")
    var
        Log: Codeunit "LT P123 Run Log";
    begin
        if T.First() then
            repeat
                Log.Add(T.Name.Value());
            until not T.Next();
        Log.Add('editable=' + Format(T.Name.Editable()));
    end;

    [PageHandler]
    procedure LinkHandler(var T: TestPage "LT P123 Run Target")
    begin
        LogRows(T);
    end;

    [PageHandler]
    procedure ViewHandler(var T: TestPage "LT P123 Run Target")
    begin
        LogRows(T);
    end;

    [PageHandler]
    procedure ModeHandler(var T: TestPage "LT P123 Run Target")
    begin
        LogRows(T);
    end;

    [Test]
    [HandlerFunctions('LinkHandler')]
    procedure P123_RunPageLink()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P123 Run Log";
        P: TestPage "LT P123 Run Base";
    begin
        Seed();
        Log.Take();
        P.OpenView();
        P.GoToKey(2);
        P.ByLink.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'Two;;editable=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ViewHandler')]
    procedure P123_RunPageView()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P123 Run Log";
        P: TestPage "LT P123 Run Base";
    begin
        Seed();
        Log.Take();
        P.OpenView();
        P.ByView.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'Two;Three;;editable=Yes;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ModeHandler')]
    procedure P123_RunPageMode()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P123 Run Log";
        P: TestPage "LT P123 Run Base";
    begin
        Seed();
        Log.Take();
        P.OpenEdit();
        P.ByMode.Invoke();
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'One;Two;Three;editable=No;');
        Observer.Verify();
    end;
}
