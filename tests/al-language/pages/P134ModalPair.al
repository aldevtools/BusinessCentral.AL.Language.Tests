// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modalpagehandler-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74111, pages 74112 74113 74114, log codeunit 74115, tests 74116 (P134)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: two [ModalPageHandler] functions in one [HandlerFunctions] list, each for another page (both typed as Page, both typed as TestPage, one of each): which handler runs for which page, in what order, and what happens when one modal page opens the other
// BC versions: 29 (27 and 28 by CI)

table 74111 "LT P134 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 74112 "LT P134 ListA"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P134 Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 74113 "LT P134 ListB"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LT P134 Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}

page 74114 "LT P134 CardC"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LT P134 Row";

    layout
    {
        area(Content)
        {
            group(G)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenB)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Result: Action;
                begin
                    Result := Page.RunModal(Page::"LT P134 ListB");
                end;
            }
        }
    }
}

codeunit 74115 "LT P134 Log"
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

codeunit 74116 "LT P134 Modal Pair"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P134 Log";

    local procedure Seed()
    var
        Row: Record "LT P134 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Log.Take();
    end;

    [ModalPageHandler]
    procedure TypedA(var P: Page "LT P134 ListA"; var Response: Action)
    var
        Row: Record "LT P134 Row";
    begin
        P.GetRecord(Row);
        Log.Add('typedA rec=' + Format(Row.Id));
        Response := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure TypedB(var P: Page "LT P134 ListB"; var Response: Action)
    var
        Row: Record "LT P134 Row";
    begin
        P.GetRecord(Row);
        Log.Add('typedB rec=' + Format(Row.Id));
        Response := Action::Cancel;
    end;

    [ModalPageHandler]
    procedure TestPageA(var P: TestPage "LT P134 ListA")
    begin
        Log.Add('testpageA first=' + Format(P.First()) + ' id=' + Format(P.Id.Value));
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TestPageB(var P: TestPage "LT P134 ListB")
    begin
        Log.Add('testpageB first=' + Format(P.First()) + ' id=' + Format(P.Id.Value));
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure TestPageCard(var P: TestPage "LT P134 CardC")
    begin
        Log.Add('testpageC id=' + Format(P.Id.Value));
        P.OpenB.Invoke();
        Log.Add('testpageC after OpenB');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('TypedA,TypedB')]
    procedure P134_TwoTypedHandlers_AThenB()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Seed();
        RA := Page.RunModal(Page::"LT P134 ListA");
        Observer.Observe('resultA', Format(RA));
        RB := Page.RunModal(Page::"LT P134 ListB");
        Observer.Observe('resultB', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultA', 'LookupOK');
        Observer.Expect('resultB', 'Cancel');
        Observer.Expect('log', 'typedA rec=0;typedB rec=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedA,TypedB')]
    procedure P134_TwoTypedHandlers_BThenA()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Seed();
        RB := Page.RunModal(Page::"LT P134 ListB");
        Observer.Observe('resultB', Format(RB));
        RA := Page.RunModal(Page::"LT P134 ListA");
        Observer.Observe('resultA', Format(RA));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultB', 'Cancel');
        Observer.Expect('resultA', 'LookupOK');
        Observer.Expect('log', 'typedB rec=0;typedA rec=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedB,TypedA')]
    procedure P134_TwoTypedHandlers_ListedInReverse()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Seed();
        RA := Page.RunModal(Page::"LT P134 ListA");
        Observer.Observe('resultA', Format(RA));
        RB := Page.RunModal(Page::"LT P134 ListB");
        Observer.Observe('resultB', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultA', 'LookupOK');
        Observer.Expect('resultB', 'Cancel');
        Observer.Expect('log', 'typedA rec=0;typedB rec=0;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedA,TypedB')]
    procedure P134_TwoTypedHandlers_WithRecordArgument()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P134 Row";
        RA: Action;
        RB: Action;
    begin
        Seed();
        Row.Get(2);
        RA := Page.RunModal(Page::"LT P134 ListA", Row);
        Row.Get(1);
        RB := Page.RunModal(Page::"LT P134 ListB", Row);
        Observer.Observe('resultA', Format(RA));
        Observer.Observe('resultB', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultA', 'LookupOK');
        Observer.Expect('resultB', 'Cancel');
        Observer.Expect('log', 'typedA rec=2;typedB rec=1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TestPageA,TestPageB')]
    procedure P134_TwoTestPageHandlers_AThenB()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Seed();
        RA := Page.RunModal(Page::"LT P134 ListA");
        Observer.Observe('resultA', Format(RA));
        RB := Page.RunModal(Page::"LT P134 ListB");
        Observer.Observe('resultB', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultA', 'LookupOK');
        Observer.Expect('resultB', 'LookupCancel');
        Observer.Expect('log', 'testpageA first=Yes id=1;testpageB first=Yes id=1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TestPageB,TestPageA')]
    procedure P134_TwoTestPageHandlers_BThenA_ListedInReverse()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Seed();
        RB := Page.RunModal(Page::"LT P134 ListB");
        Observer.Observe('resultB', Format(RB));
        RA := Page.RunModal(Page::"LT P134 ListA");
        Observer.Observe('resultA', Format(RA));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultB', 'LookupCancel');
        Observer.Expect('resultA', 'LookupOK');
        Observer.Expect('log', 'testpageB first=Yes id=1;testpageA first=Yes id=1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TypedA,TestPageB')]
    procedure P134_OneTypedOneTestPage_AThenB()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Seed();
        RA := Page.RunModal(Page::"LT P134 ListA");
        Observer.Observe('resultA', Format(RA));
        RB := Page.RunModal(Page::"LT P134 ListB");
        Observer.Observe('resultB', Format(RB));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultA', 'LookupOK');
        Observer.Expect('resultB', 'LookupCancel');
        Observer.Expect('log', 'typedA rec=0;testpageB first=Yes id=1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TestPageA,TypedB')]
    procedure P134_OneTestPageOneTyped_BThenA()
    var
        Observer: Codeunit "Probe Observer";
        RA: Action;
        RB: Action;
    begin
        Seed();
        RB := Page.RunModal(Page::"LT P134 ListB");
        Observer.Observe('resultB', Format(RB));
        RA := Page.RunModal(Page::"LT P134 ListA");
        Observer.Observe('resultA', Format(RA));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultB', 'Cancel');
        Observer.Expect('resultA', 'LookupOK');
        Observer.Expect('log', 'typedB rec=0;testpageA first=Yes id=1;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('TestPageCard,TestPageB')]
    procedure P134_ModalPageOpensAnotherModalPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P134 Row";
        RC: Action;
    begin
        Seed();
        Row.Get(1);
        RC := Page.RunModal(Page::"LT P134 CardC", Row);
        Observer.Observe('resultC', Format(RC));
        Observer.Observe('log', Log.Take());
        Observer.Expect('resultC', 'LookupOK');
        Observer.Expect('log', 'testpageC id=1;testpageB first=Yes id=1;testpageC after OpenB;');
        Observer.Verify();
    end;
}
