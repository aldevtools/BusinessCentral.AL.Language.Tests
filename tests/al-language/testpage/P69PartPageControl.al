// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-currpage
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 71173, pages 71174 (part) and 71175 (host), codeunits 71176 (log) and 71177
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles GitHub issue #69 (Inferred behaviors waiting for a pin): CurrPage.<Part>.Page.Proc() when the part page has a control named Page
// Facts: a public procedure of the part page called through CurrPage.Part.Page, with the part page having a field named Page; the same through a TestPage
// BC versions: 29 (27 and 28 by CI)

table 71173 "LT P69 Part Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Page"; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 71176 "LT P69 Part Log"
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

page 71174 "LT P69 Part Page"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P69 Part Row";

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field("Page"; Rec."Page") { ApplicationArea = All; }
            }
        }
    }

    procedure Mark(Text: Text): Text
    var
        Log: Codeunit "LT P69 Part Log";
    begin
        Log.Add('Mark:' + Text);
        exit('marked ' + Text);
    end;

    procedure CountRows(): Integer
    begin
        exit(Rec.Count());
    end;
}

page 71175 "LT P69 Part Host"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT P69 Part Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            part(Lines; "LT P69 Part Page")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CallPart)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P69 Part Log";
                    Result: Text;
                begin
                    Result := CurrPage.Lines.Page.Mark('from host');
                    Log.Add('result=' + Result);
                end;
            }
            action(CountPart)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT P69 Part Log";
                begin
                    Log.Add('count=' + Format(CurrPage.Lines.Page.CountRows()));
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "LT P69 Part Log";
    begin
        Log.Add('host open');
        CurrPage.Lines.Page.Mark('on open');
    end;
}

codeunit 71177 "LT P69 Part Page Control"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P69 Part Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row."Page" := 'first';
        Row.Insert();
        Row.Id := 2;
        Row."Page" := 'second';
        Row.Insert();
    end;

    [Test]
    procedure PartPage_CallProcedureThroughCurrPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P69 Part Log";
        P: TestPage "LT P69 Part Host";
    begin
        Seed();
        Log.Take();
        P.OpenView();
        Observer.Observe('open', Log.Take());
        P.CallPart.Invoke();
        Observer.Observe('call_part', Log.Take());
        P.CountPart.Invoke();
        Observer.Observe('count_part', Log.Take());
        Observer.Expect('open', 'host open;Mark:on open;');
        Observer.Expect('call_part', 'Mark:from host;result=marked from host;');
        Observer.Expect('count_part', 'count=2;');
        Observer.Verify();
    end;

    [Test]
    procedure PartPage_ControlNamedPage()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P69 Part Host";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('first_id', Format(P.Lines.Id.Value()));
        Observer.Observe('first_page_field', P.Lines."Page".Value());
        P.Lines.Next();
        Observer.Observe('second_page_field', P.Lines."Page".Value());
        P.Lines.Last();
        Observer.Observe('last_page_field', P.Lines."Page".Value());
        Observer.Expect('first_id', '1');
        Observer.Expect('first_page_field', 'first');
        Observer.Expect('second_page_field', 'second');
        Observer.Expect('last_page_field', 'second');
        Observer.Verify();
    end;

    [Test]
    procedure PartPage_StandalonePartAsTestPage()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT P69 Part Page";
    begin
        Seed();
        P.OpenView();
        Observer.Observe('first_page_field', P."Page".Value());
        P.Next();
        Observer.Observe('second_page_field', P."Page".Value());
        Observer.Expect('first_page_field', 'first');
        Observer.Expect('second_page_field', 'second');
        Observer.Verify();
    end;
}
