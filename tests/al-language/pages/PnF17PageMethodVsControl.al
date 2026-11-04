// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-update-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73899, page 73900, codeunits 73901 (log) and 73902
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "A page method call with a control or action of the same name" (Must-not-compile checks)
// Facts: a page with an action named Update and a field named Close: CurrPage.Update(false), CurrPage.Close() inside actions, and the action Update invoked from a TestPage
// BC versions: 29 (27 and 28 by CI)

table 73899 "LT PnF PM Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Close; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73901 "LT PnF PM Log"
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

page 73900 "LT PnF PM Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF PM Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Close; Rec.Close) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Update)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF PM Log";
                begin
                    Log.Add('action Update');
                end;
            }
            action(CallUpdate)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF PM Log";
                begin
                    Log.Add('before CurrPage.Update');
                    CurrPage.Update(false);
                    Log.Add('after CurrPage.Update');
                end;
            }
            action(CallClose)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF PM Log";
                begin
                    Log.Add('before CurrPage.Close');
                    CurrPage.Close();
                    Log.Add('after CurrPage.Close');
                end;
            }
        }
    }

    trigger OnClosePage()
    var
        Log: Codeunit "LT PnF PM Log";
    begin
        Log.Add('OnClosePage');
    end;
}

codeunit 73902 "LT PnF Page Method Control"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT PnF PM Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Close := 'text';
        Row.Insert();
    end;

    [Test]
    procedure PageMethod_UpdateAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF PM Log";
        P: TestPage "LT PnF PM Card";
    begin
        Seed();
        Log.Take();
        P.OpenView();
        P.Update.Invoke();
        Observer.Observe('action_update', Log.Take());
        P.CallUpdate.Invoke();
        Observer.Observe('call_update', Log.Take());
        Observer.Expect('action_update', 'action Update;');
        Observer.Expect('call_update', 'before CurrPage.Update;after CurrPage.Update;');
        Observer.Verify();
    end;

    [Test]
    procedure PageMethod_CloseCall()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF PM Log";
        P: TestPage "LT PnF PM Card";
    begin
        Seed();
        Log.Take();
        P.OpenView();
        P.CallClose.Invoke();
        Observer.Observe('call_close', Log.Take());
        Observer.Expect('call_close', 'before CurrPage.Close;OnClosePage;after CurrPage.Close;');
        Observer.Verify();
    end;
}
