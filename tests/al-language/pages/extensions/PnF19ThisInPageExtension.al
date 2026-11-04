// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-this-keyword
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73905, codeunit 73906 (log), page 73907, page extension 73908, codeunit 73909
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "this.Member of the base report in a reportextension trigger" (Page extension overload of a base page procedure; the pageextension half) and
//   "this.Member in a report, page, xmlport or query" (a procedure of the base object called through this from an extension)
// Facts: in a page extension trigger and action: this.BaseProc() (protected and public), this.BaseVar (protected variable), this.ExtProc() and this.ExtVar, with a base procedure of the same name as an extension one
// BC versions: 29 (27 and 28 by CI)

table 73905 "LT PnF TP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73906 "LT PnF TP Log"
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

page 73907 "LT PnF TP Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF TP Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    protected var
        ProtVar: Integer;

    protected procedure BaseProtected(): Text
    begin
        exit('base protected');
    end;

    procedure BasePublic(): Text
    begin
        exit('base public');
    end;

    procedure Shared(): Text
    begin
        exit('base shared');
    end;

    trigger OnOpenPage()
    begin
        this.ProtVar := 5;
    end;
}

pageextension 73908 "LT PnF TP Ext" extends "LT PnF TP Card"
{
    actions
    {
        addlast(Processing)
        {
            action(ThisCalls)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF TP Log";
                begin
                    Log.Add('protected=' + this.BaseProtected());
                    Log.Add('public=' + this.BasePublic());
                    Log.Add('protvar=' + Format(this.ProtVar));
                    Log.Add('extproc=' + this.ExtProc());
                    Log.Add('shared=' + this.Shared(true));
                end;
            }
            action(BareCalls)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Log: Codeunit "LT PnF TP Log";
                begin
                    Log.Add('bare protected=' + BaseProtected());
                    Log.Add('bare protvar=' + Format(ProtVar));
                end;
            }
        }
    }

    var
        ExtVar: Integer;

    procedure ExtProc(): Text
    begin
        exit('ext proc');
    end;

    procedure Shared(Flag: Boolean): Text
    begin
        exit('ext shared ' + Format(Flag));
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PnF TP Log";
    begin
        Log.Add('AGR ' + this.ExtProc() + ' ' + this.BasePublic());
    end;
}

codeunit 73909 "LT PnF This In PageExt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure This_PageExtension_Calls()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnF TP Log";
        Row: Record "LT PnF TP Row";
        P: TestPage "LT PnF TP Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Log.Take();
        P.OpenView();
        Observer.Observe('open', Log.Take());
        asserterror P.ThisCalls.Invoke();
        Observer.ObserveError('af157');
        Observer.Observe('this_calls', Log.Take());
        P.BareCalls.Invoke();
        Observer.Observe('bare_calls', Log.Take());
        Observer.Expect('open', 'AGR ext proc base public;');
        Observer.Expect('af157|text', 'The another object refers to a global variable on PageExtension with ID 73908 that no longer seems to exists. Try to recompile dependent extensions.');
        Observer.Expect('af157|code', 'TestWrapped:GlobalVariableNotFound');
        Observer.Expect('this_calls', 'AGR ext proc base public;protected=base protected;public=base public;');
        Observer.Expect('bare_calls', 'AGR ext proc base public;AGR ext proc base public;bare protected=base protected;bare protvar=5;AGR ext proc base public;');
        Observer.Verify();
    end;
}
