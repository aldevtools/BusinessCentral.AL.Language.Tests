// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); HiddenPartFixture.al (table 71354, log codeunit 71355), self-contained pages and test codeunit 71375
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: CurrPage.Editable read run by a procedure of a part page (Visible = false literal, and Visible = a Boolean variable that is false at open) that the host card calls from OnAfterGetCurrRecord: error text and code, and which part triggers run.
// Risky: none known; if this file does not compile only this method is dropped.

page 71372 "LT HP Editable Part"
{
    PageType = ListPart;
    SourceTable = "LT HiddenPart Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure RunEditable()
    var
        Log: Codeunit "LT HiddenPart Log 2";
    begin
        Log.Add('proc-start');
        Log.Add('editable=' + Format(CurrPage.Editable));
        Log.Add('proc-end');
    end;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT HiddenPart Log 2";
    begin
        Log.Add('part-OnOpenPage');
    end;

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT HiddenPart Log 2";
    begin
        Log.Add('part-OnAfterGetRecord:' + Format(Rec.Id));
    end;
}

page 71373 "LT HP Editable Literal"
{
    PageType = Card;
    SourceTable = "LT HiddenPart Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT HP Editable Part")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT HiddenPart Log 2";
    begin
        Log.Add('host-start');
        CurrPage.PartCtl.Page.RunEditable();
        Log.Add('host-end');
    end;
}

page 71374 "LT HP Editable Expr"
{
    PageType = Card;
    SourceTable = "LT HiddenPart Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            part(PartCtl; "LT HP Editable Part")
            {
                ApplicationArea = All;
                Visible = ShowPart;
            }
        }
    }

    var
        ShowPart: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        Log: Codeunit "LT HiddenPart Log 2";
    begin
        Log.Add('host-start');
        CurrPage.PartCtl.Page.RunEditable();
        Log.Add('host-end');
    end;
}

codeunit 71375 "LT HP Editable Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT HiddenPart Row";
        Log: Codeunit "LT HiddenPart Log 2";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Log.Reset();
    end;

    [TryFunction]
    local procedure TryOpenLiteral(var Host: TestPage "LT HP Editable Literal")
    begin
        Host.OpenEdit();
    end;

    [TryFunction]
    local procedure TryOpenExpr(var Host: TestPage "LT HP Editable Expr")
    begin
        Host.OpenEdit();
    end;

    [Test]
    procedure Editable_LiteralInvisible_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT HiddenPart Log 2";
        Host: TestPage "LT HP Editable Literal";
        Opened: Boolean;
    begin
        Seed();
        Opened := TryOpenLiteral(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error text', GetLastErrorText());
        Observer.Observe('error code', GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        if Opened then begin
            Log.Reset();
            Observer.Observe('next', Format(Host.Next()));
            Observer.Observe('log after next', Log.Dump());
            Host.Close();
        end;
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error text', '');
        Observer.Expect('error code', '');
        Observer.Expect('log', '[host-start | proc-start | editable=Yes | proc-end | host-end]');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log after next', '[host-start | proc-start | editable=Yes | proc-end | host-end]');
        Observer.Verify();
    end;

    [Test]
    procedure Editable_ExprInvisible_OpenEdit()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT HiddenPart Log 2";
        Host: TestPage "LT HP Editable Expr";
        Opened: Boolean;
    begin
        Seed();
        Opened := TryOpenExpr(Host);
        Observer.Observe('opened', Format(Opened));
        Observer.Observe('error text', GetLastErrorText());
        Observer.Observe('error code', GetLastErrorCode());
        Observer.Observe('log', Log.Dump());
        if Opened then begin
            Log.Reset();
            Observer.Observe('next', Format(Host.Next()));
            Observer.Observe('log after next', Log.Dump());
            Host.Close();
        end;
        Observer.Expect('opened', 'Yes');
        Observer.Expect('error text', '');
        Observer.Expect('error code', '');
        Observer.Expect('log', '[part-OnOpenPage | host-start | proc-start | editable=Yes | proc-end | host-end | part-OnAfterGetRecord:1 | part-OnAfterGetRecord:2 | part-OnAfterGetRecord:1]');
        Observer.Expect('next', 'Yes');
        Observer.Expect('log after next', '[host-start | proc-start | editable=Yes | proc-end | host-end]');
        Observer.Verify();
    end;
}

codeunit 70013 "LT HiddenPart Log 2"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}
