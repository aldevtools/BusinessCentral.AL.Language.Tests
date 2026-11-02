// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-setvalue-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); enum 94589, table 94590, pages 94591-94594, test codeunit 94595
// Probe (writer Y86, al-runtime-rs assumptions testpage-setvalue-blank-enum-member, testpage-setvalue-blank-option-member and
// testpage-assertequals-integer-on-text-control): controls bound to page variables. (1) An Enum variable control (value 0 " ", caption ' ')
// on a page without a source table, on a list with rows and on a list without rows: SetValue(0), SetValue(' '), SetValue of the member name,
// from another value. (2) An Option variable control whose first member is " " and has no OptionCaption: SetValue(' '), SetValue(0) after
// SetValue('A'). (3) AssertEquals of Integer, BigInteger and Decimal values on a Text[30] and a Code[30] control holding digits.
// BC versions: 27, 28, 29

enum 94589 "LT Y86 Blank Enum"
{
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; Alpha) { Caption = 'Alpha'; }
    value(2; Beta) { Caption = 'Beta'; }
}

table 94590 "LT Y86 Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

page 94591 "LT Y86 NoSource Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(EnumCtl; EnumVar) { ApplicationArea = All; }
            field(OptCtl; OptVar) { ApplicationArea = All; }
            field(TextCtl; TextVar) { ApplicationArea = All; }
            field(CodeCtl; CodeVar) { ApplicationArea = All; }
        }
    }

    var
        EnumVar: Enum "LT Y86 Blank Enum";
        OptVar: Option " ",A,B;
        TextVar: Text[30];
        CodeVar: Code[30];

    trigger OnOpenPage()
    begin
        TextVar := '1000';
        CodeVar := '-5';
    end;
}

page 94592 "LT Y86 Src List"
{
    PageType = List;
    SourceTable = "LT Y86 Src";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(EnumCtl; EnumVar) { ApplicationArea = All; }
            field(OptCtl; OptVar) { ApplicationArea = All; }
            field(TextCtl; TextVar) { ApplicationArea = All; }
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    var
        EnumVar: Enum "LT Y86 Blank Enum";
        OptVar: Option " ",A,B;
        TextVar: Text[30];

    trigger OnOpenPage()
    begin
        TextVar := '1000';
    end;
}

page 94593 "LT Y86 Variable Card Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(EnumCtl; EnumVar) { ApplicationArea = All; }
            field(OptCtl; OptVar) { ApplicationArea = All; }
        }
    }

    var
        EnumVar: Enum "LT Y86 Blank Enum";
        OptVar: Option " ",A,B;
}

page 94594 "LT Y86 Host For Part"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            part(VarPart; "LT Y86 Variable Card Part") { ApplicationArea = All; }
        }
    }
}

codeunit 94595 "LT Y86 TestPage Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetInt(var TP: TestPage "LT Y86 NoSource Card"; Ctl: Text; V: Integer)
    begin
        case Ctl of
            'enum':
                TP.EnumCtl.SetValue(V);
            'opt':
                TP.OptCtl.SetValue(V);
        end;
    end;

    [TryFunction]
    local procedure TrySetText(var TP: TestPage "LT Y86 NoSource Card"; Ctl: Text; V: Text)
    begin
        case Ctl of
            'enum':
                TP.EnumCtl.SetValue(V);
            'opt':
                TP.OptCtl.SetValue(V);
        end;
    end;

    local procedure ValueOf(var TP: TestPage "LT Y86 NoSource Card"; Ctl: Text): Text
    begin
        case Ctl of
            'enum':
                exit('[' + TP.EnumCtl.Value() + ']');
            'opt':
                exit('[' + TP.OptCtl.Value() + ']');
        end;
    end;

    local procedure RunInt(var Obs: Codeunit "Probe Observer"; var TP: TestPage "LT Y86 NoSource Card"; Ctl: Text; V: Integer)
    var
        Name: Text;
    begin
        Name := Ctl + ' int ' + Format(V);
        ClearLastError();
        if TrySetInt(TP, Ctl, V) then
            Obs.Observe(Name, 'ok ' + ValueOf(TP, Ctl))
        else begin
            Obs.Observe(Name, 'error ' + GetLastErrorCode() + ': ' + GetLastErrorText() + ' ' + ValueOf(TP, Ctl));
            ClearLastError();
        end;
    end;

    local procedure RunText(var Obs: Codeunit "Probe Observer"; var TP: TestPage "LT Y86 NoSource Card"; Ctl: Text; V: Text)
    var
        Name: Text;
    begin
        Name := Ctl + ' text [' + V + ']';
        ClearLastError();
        if TrySetText(TP, Ctl, V) then
            Obs.Observe(Name, 'ok ' + ValueOf(TP, Ctl))
        else begin
            Obs.Observe(Name, 'error ' + GetLastErrorCode() + ': ' + GetLastErrorText() + ' ' + ValueOf(TP, Ctl));
            ClearLastError();
        end;
    end;

    [Test]
    procedure Y86_NoSourcePage_EnumAndOptionBlank()
    var
        Obs: Codeunit "Probe Observer";
        TP: TestPage "LT Y86 NoSource Card";
    begin
        TP.OpenEdit();
        Obs.Observe('enum start', ValueOf(TP, 'enum'));
        Obs.Observe('opt start', ValueOf(TP, 'opt'));
        RunText(Obs, TP, 'enum', 'Beta');
        RunInt(Obs, TP, 'enum', 0);
        RunText(Obs, TP, 'enum', 'Alpha');
        RunText(Obs, TP, 'enum', ' ');
        RunText(Obs, TP, 'enum', 'Beta');
        RunInt(Obs, TP, 'enum', 1);
        RunInt(Obs, TP, 'enum', 5);
        RunText(Obs, TP, 'opt', 'B');
        RunText(Obs, TP, 'opt', ' ');
        RunText(Obs, TP, 'opt', 'A');
        RunInt(Obs, TP, 'opt', 0);
        RunText(Obs, TP, 'opt', 'B');
        RunText(Obs, TP, 'opt', '');
        RunInt(Obs, TP, 'opt', 7);
        TP.Close();
        Obs.Finish();
    end;

    [Test]
    procedure Y86_SourceList_EnumAndOptionBlank()
    var
        Obs: Codeunit "Probe Observer";
        TP: TestPage "LT Y86 Src List";
        R: Record "LT Y86 Src";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        R.Id := 2;
        R.Insert();
        TP.OpenEdit();
        TP.EnumCtl.SetValue('Beta');
        Obs.Observe('enum after Beta', '[' + TP.EnumCtl.Value() + ']');
        TP.EnumCtl.SetValue(0);
        Obs.Observe('enum after 0', '[' + TP.EnumCtl.Value() + ']');
        TP.EnumCtl.SetValue('Alpha');
        TP.EnumCtl.SetValue(' ');
        Obs.Observe('enum after Alpha then text blank', '[' + TP.EnumCtl.Value() + ']');
        TP.OptCtl.SetValue('B');
        TP.OptCtl.SetValue(' ');
        Obs.Observe('opt after B then text blank', '[' + TP.OptCtl.Value() + ']');
        TP.OptCtl.SetValue('A');
        TP.OptCtl.SetValue(0);
        Obs.Observe('opt after A then 0', '[' + TP.OptCtl.Value() + ']');
        TP.GoToKey(2);
        TP.EnumCtl.SetValue('Beta');
        TP.EnumCtl.SetValue(0);
        Obs.Observe('enum on row 2 after 0', '[' + TP.EnumCtl.Value() + ']' + ' id=' + Format(TP.Id.Value()));
        TP.Close();
        Obs.Finish();
    end;

    [Test]
    procedure Y86_SourceListWithoutRows_EnumAndOptionBlank()
    var
        Obs: Codeunit "Probe Observer";
        TP: TestPage "LT Y86 Src List";
        R: Record "LT Y86 Src";
    begin
        R.DeleteAll();
        TP.OpenEdit();
        TP.EnumCtl.SetValue('Beta');
        Obs.Observe('enum after Beta', '[' + TP.EnumCtl.Value() + ']');
        TP.EnumCtl.SetValue(0);
        Obs.Observe('enum after 0', '[' + TP.EnumCtl.Value() + ']');
        TP.OptCtl.SetValue('B');
        TP.OptCtl.SetValue(' ');
        Obs.Observe('opt after B then text blank', '[' + TP.OptCtl.Value() + ']');
        TP.OptCtl.SetValue('A');
        TP.OptCtl.SetValue(0);
        Obs.Observe('opt after A then 0', '[' + TP.OptCtl.Value() + ']');
        TP.Close();
        Obs.Finish();
    end;

    [Test]
    procedure Y86_PartVariables_EnumAndOptionBlank()
    var
        Obs: Codeunit "Probe Observer";
        TP: TestPage "LT Y86 Host For Part";
    begin
        TP.OpenEdit();
        TP.VarPart.EnumCtl.SetValue('Beta');
        TP.VarPart.EnumCtl.SetValue(0);
        Obs.Observe('part enum after 0', '[' + TP.VarPart.EnumCtl.Value() + ']');
        TP.VarPart.OptCtl.SetValue('B');
        TP.VarPart.OptCtl.SetValue(' ');
        Obs.Observe('part opt after text blank', '[' + TP.VarPart.OptCtl.Value() + ']');
        TP.Close();
        Obs.Finish();
    end;

    [TryFunction]
    local procedure TryAssertInt(var TP: TestPage "LT Y86 NoSource Card"; Ctl: Text; V: Integer)
    begin
        if Ctl = 'text' then
            TP.TextCtl.AssertEquals(V)
        else
            TP.CodeCtl.AssertEquals(V);
    end;

    [TryFunction]
    local procedure TryAssertBig(var TP: TestPage "LT Y86 NoSource Card"; Ctl: Text; V: BigInteger)
    begin
        if Ctl = 'text' then
            TP.TextCtl.AssertEquals(V)
        else
            TP.CodeCtl.AssertEquals(V);
    end;

    [TryFunction]
    local procedure TryAssertDec(var TP: TestPage "LT Y86 NoSource Card"; Ctl: Text; V: Decimal)
    begin
        if Ctl = 'text' then
            TP.TextCtl.AssertEquals(V)
        else
            TP.CodeCtl.AssertEquals(V);
    end;

    local procedure Result(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error ' + GetLastErrorCode() + ': ' + GetLastErrorText());
    end;

    [Test]
    procedure Y86_AssertEquals_NumbersOnTextAndCodeControls()
    var
        Obs: Codeunit "Probe Observer";
        TP: TestPage "LT Y86 NoSource Card";
    begin
        TP.OpenEdit();
        // text control holds '1000', code control holds '-5'
        ClearLastError();
        Obs.Observe('text int 1000', Result(TryAssertInt(TP, 'text', 1000)));
        ClearLastError();
        Obs.Observe('text int 1001', Result(TryAssertInt(TP, 'text', 1001)));
        ClearLastError();
        Obs.Observe('text big 1000', Result(TryAssertBig(TP, 'text', 1000)));
        ClearLastError();
        Obs.Observe('text big 1001', Result(TryAssertBig(TP, 'text', 1001)));
        ClearLastError();
        Obs.Observe('text dec 1000', Result(TryAssertDec(TP, 'text', 1000)));
        ClearLastError();
        Obs.Observe('text dec 1000.5', Result(TryAssertDec(TP, 'text', 1000.5)));
        ClearLastError();
        Obs.Observe('code int -5', Result(TryAssertInt(TP, 'code', -5)));
        ClearLastError();
        Obs.Observe('code int 5', Result(TryAssertInt(TP, 'code', 5)));
        ClearLastError();
        Obs.Observe('code big -5', Result(TryAssertBig(TP, 'code', -5)));
        ClearLastError();
        Obs.Observe('code big 5', Result(TryAssertBig(TP, 'code', 5)));
        ClearLastError();
        Obs.Observe('code dec -5', Result(TryAssertDec(TP, 'code', -5)));
        TP.TextCtl.SetValue('7');
        ClearLastError();
        Obs.Observe('text int 7 after SetValue', Result(TryAssertInt(TP, 'text', 7)));
        ClearLastError();
        Obs.Observe('text big 7 after SetValue', Result(TryAssertBig(TP, 'text', 7)));
        TP.Close();
        Obs.Finish();
    end;
}
