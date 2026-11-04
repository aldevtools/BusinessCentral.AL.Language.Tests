// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 73852, page 73853, page extensions 73854 and 73855, codeunit 73856
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "SaveValues on a page that page extensions extend" (GetLastErrorText flag, SaveValues with page extensions, ... issue 35)
// Facts: a SaveValues card with a base field bound to a variable, an extension field bound to the extension's own variable, an extension field bound to Rec, an extension
//   field bound to a protected variable of the base page and a field of a second extension bound to that extension's variable: set all, close with OK or Cancel, reopen, read all
// BC versions: 29 (27 and 28 by CI)

table 73852 "LT PnF SV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; X; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 73853 "LT PnF SV Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PnF SV Row";
    SaveValues = true;

    layout
    {
        area(Content)
        {
            field(A; Var1)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Var1: Text[30];

    protected var
        Var2: Text[30];
}

pageextension 73854 "LT PnF SV Ext1" extends "LT PnF SV Card"
{
    layout
    {
        addlast(Content)
        {
            field(B; ExtVar)
            {
                ApplicationArea = All;
            }
            field(C; Rec.X)
            {
                ApplicationArea = All;
            }
            field(D; Var2)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        ExtVar: Text[30];
}

pageextension 73855 "LT PnF SV Ext2" extends "LT PnF SV Card"
{
    layout
    {
        addlast(Content)
        {
            field(E; Ext2Var)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        Ext2Var: Text[30];
}

codeunit 73856 "LT PnF SV Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Text;
        SeenA: Text;
        SeenB: Text;
        SeenC: Text;
        SeenD: Text;
        SeenE: Text;

    [ModalPageHandler]
    procedure CardHandler(var P: TestPage "LT PnF SV Card")
    begin
        case Mode of
            'set_ok':
                begin
                    P.A.SetValue('a1');
                    P.B.SetValue('b1');
                    P.C.SetValue('c1');
                    P.D.SetValue('d1');
                    P.E.SetValue('e1');
                    P.OK().Invoke();
                end;
            'set_cancel':
                begin
                    P.A.SetValue('a2');
                    P.B.SetValue('b2');
                    P.C.SetValue('c2');
                    P.D.SetValue('d2');
                    P.E.SetValue('e2');
                    P.Cancel().Invoke();
                end;
            'read':
                begin
                    SeenA := P.A.Value();
                    SeenB := P.B.Value();
                    SeenC := P.C.Value();
                    SeenD := P.D.Value();
                    SeenE := P.E.Value();
                    P.Cancel().Invoke();
                end;
        end;
    end;

    local procedure Open(NewMode: Text)
    var
        Row: Record "LT PnF SV Row";
    begin
        Mode := NewMode;
        if not Row.Get(1) then begin
            Row.Id := 1;
            Row.Insert();
        end;
        Page.RunModal(Page::"LT PnF SV Card", Row);
    end;

    local procedure Prepare()
    var
        Row: Record "LT PnF SV Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure SaveValues_Ext_OkThenReopen()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF SV Row";
    begin
        Prepare();
        asserterror Open('read');
        Observer.ObserveError('af164');
        Observer.Observe('first_A', SeenA);
        Observer.Observe('first_B', SeenB);
        Observer.Observe('first_C', SeenC);
        Observer.Observe('first_D', SeenD);
        Observer.Observe('first_E', SeenE);
        Open('set_ok');
        Observer.Observe('af171', 'no error');
        asserterror Open('read');
        Observer.ObserveError('af173');
        Observer.Observe('second_A', SeenA);
        Observer.Observe('second_B', SeenB);
        Observer.Observe('second_C', SeenC);
        Observer.Observe('second_D', SeenD);
        Observer.Observe('second_E', SeenE);
        if Row.Get(1) then;
        Observer.Observe('stored_X', Row.X);
        Observer.Expect('af164|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af164|code', 'TestActionNotFound');
        Observer.Expect('first_A', '');
        Observer.Expect('first_B', '');
        Observer.Expect('first_C', '');
        Observer.Expect('first_D', '');
        Observer.Expect('first_E', '');
        Observer.Expect('af171', 'no error');
        Observer.Expect('af173|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af173|code', 'TestActionNotFound');
        Observer.Expect('second_A', 'a1');
        Observer.Expect('second_B', 'b1');
        Observer.Expect('second_C', 'c1');
        Observer.Expect('second_D', 'd1');
        Observer.Expect('second_E', 'e1');
        Observer.Expect('stored_X', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure SaveValues_Ext_CancelThenReopen()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT PnF SV Row";
    begin
        Prepare();
        asserterror Open('set_cancel');
        Observer.ObserveError('af191');
        asserterror Open('read');
        Observer.ObserveError('af194');
        Observer.Observe('A', SeenA);
        Observer.Observe('B', SeenB);
        Observer.Observe('C', SeenC);
        Observer.Observe('D', SeenD);
        Observer.Observe('E', SeenE);
        if Row.Get(1) then;
        Observer.Observe('stored_X', Row.X);
        Observer.Expect('af191|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af191|code', 'TestActionNotFound');
        Observer.Expect('af194|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af194|code', 'TestActionNotFound');
        Observer.Expect('A', '');
        Observer.Expect('B', '');
        Observer.Expect('C', '');
        Observer.Expect('D', '');
        Observer.Expect('E', '');
        Observer.Expect('stored_X', '');
        Observer.Verify();
    end;
}
