// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); tables 88079-88082 and 88084, log 88089, pages 88146-88148, report 88149, test codeunit 88095
// Probe: written against BC on the corpus CI matrix and local BC 27.5, 28.5 and 29.0; every literal asserted below is what that tier produced.
// Facts: TestPage SetValue into a control bound to a page variable with a TableRelation (runner issue 8339: the reporter
//   measured that the upper-case company name typed into a Text variable related to Company gives the stored name). For each input (exact, other letter
//   case, unique prefix, ambiguous prefix, no match, blank) the control value after SetValue (or the error) and the variable the page holds (an action logs
//   it). Relations: Company (asserted only as equal or not to CompanyName()), a Text key, a non-key field, a conditional relation, a Code variable, a Text
//   variable to a Code key, an Integer key, ValidateTableRelation = false, a control with OnLookup, a table with TableType = Temporary, a variable an
//   extension adds, a field of Rec, and a request page variable.
// BC versions: all (CI)

table 88079 "TPL Rel Text"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Text[30]) { }
        field(2; Description; Text[50]) { }
        field(3; Kind; Integer) { }
    }

    keys { key(PK; Name) { Clustered = true; } }
}

table 88080 "TPL Rel Code"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 88081 "TPL Rel Int"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 88082 "TPL Rel Holder"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Code[10]) { }
        field(2; RelName; Text[30]) { TableRelation = "TPL Rel Text"; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 88084 "TPL Rel Temp"
{
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; Name; Text[30]) { }
    }

    keys { key(PK; Name) { Clustered = true; } }
}

page 88146 "TPL Rel Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CompF; CompName) { ApplicationArea = All; TableRelation = Company; }
                field(TextKeyF; TextKey) { ApplicationArea = All; TableRelation = "TPL Rel Text"; }
                field(NonKeyF; TextNonKey) { ApplicationArea = All; TableRelation = "TPL Rel Text".Description; }
                field(CondF; TextCond) { ApplicationArea = All; TableRelation = "TPL Rel Text" where(Kind = const(1)); }
                field(CodeVarF; CodeVar) { ApplicationArea = All; TableRelation = "TPL Rel Text"; }
                field(CodeKeyF; TextToCode) { ApplicationArea = All; TableRelation = "TPL Rel Code"; }
                field(IntF; IntVar) { ApplicationArea = All; TableRelation = "TPL Rel Int"; }
                field(LookupF; WithLookup)
                {
                    ApplicationArea = All;
                    TableRelation = "TPL Rel Text";

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(false);
                    end;
                }
                field(TempF; TempRel) { ApplicationArea = All; TableRelation = "TPL Rel Temp"; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EchoCompName)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(CompName));
                end;
            }
            action(EchoTextKey)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(TextKey));
                end;
            }
            action(EchoTextNonKey)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(TextNonKey));
                end;
            }
            action(EchoTextCond)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(TextCond));
                end;
            }
            action(EchoCodeVar)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(CodeVar));
                end;
            }
            action(EchoTextToCode)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(TextToCode));
                end;
            }
            action(EchoIntVar)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(IntVar));
                end;
            }
            action(EchoWithLookup)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(WithLookup));
                end;
            }
            action(EchoTempRel)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Log.Add(Format(TempRel));
                end;
            }
        }
    }

    var
        Log: Codeunit "TPL Rel Log";
        CompName: Text[30];
        TextKey: Text[30];
        TextNonKey: Text[50];
        TextCond: Text[30];
        CodeVar: Code[30];
        TextToCode: Text[20];
        IntVar: Integer;
        WithLookup: Text[30];
        TempRel: Text[30];
}

page 88147 "TPL Rel Holder Card"
{
    PageType = Card;
    SourceTable = "TPL Rel Holder";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(IdF; Rec.Id) { ApplicationArea = All; }
                field(RelNameF; Rec.RelName) { ApplicationArea = All; }
            }
        }
    }
}

pageextension 88148 "TPL Rel Card Ext" extends "TPL Rel Card"
{
    layout
    {
        addlast(General)
        {
            field(ExtF; ExtText) { ApplicationArea = All; TableRelation = "TPL Rel Text"; }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(EchoExtText)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    ExtLog.Add(ExtText);
                end;
            }
        }
    }

    var
        ExtLog: Codeunit "TPL Rel Log";
        ExtText: Text[30];
}

report 88149 "TPL Rel Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(CompF; CompName) { ApplicationArea = All; TableRelation = Company; }
                field(TextKeyF; TextKey) { ApplicationArea = All; TableRelation = "TPL Rel Text"; }
            }
        }
    }

    trigger OnPreReport()
    begin
        Log.Add('comp=' + Format(CompName = CompanyName()) + ' text=' + TextKey);
    end;

    var
        Log: Codeunit "TPL Rel Log";
        CompName: Text[30];
        TextKey: Text[30];
}

codeunit 88089 "TPL Rel Log"
{
    SingleInstance = true;

    var
        Buffer: Text;
        CurrentMode: Text;

    procedure Reset()
    begin
        Buffer := '';
        CurrentMode := '';
    end;

    procedure Add(Entry: Text)
    begin
        Buffer += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Buffer;
        Buffer := '';
        exit(Result);
    end;

    procedure SetMode(NewMode: Text)
    begin
        CurrentMode := NewMode;
    end;

    procedure Mode(): Text
    begin
        exit(CurrentMode);
    end;
}

codeunit 88095 "TPL Relation SetValue"
{
    Subtype = Test;

    var
        Log: Codeunit "TPL Rel Log";

    [Test]
    procedure Company_Upper()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := UpperCase(CompanyName());
        P.OpenEdit();
        if TrySet_CompF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('valueIsCompanyName', Format(P.CompF.Value() = CompanyName()));
        Observer.Observe('valueIsTyped', Format(P.CompF.Value() = Typed));
        P.EchoCompName.Invoke();
        Echo := Log.Take();
        Observer.Observe('varIsCompanyName', Format(Echo = CompanyName() + ';'));
        Observer.Observe('varIsTyped', Format(Echo = Typed + ';'));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Company_Lower()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := LowerCase(CompanyName());
        P.OpenEdit();
        if TrySet_CompF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('valueIsCompanyName', Format(P.CompF.Value() = CompanyName()));
        Observer.Observe('valueIsTyped', Format(P.CompF.Value() = Typed));
        P.EchoCompName.Invoke();
        Echo := Log.Take();
        Observer.Observe('varIsCompanyName', Format(Echo = CompanyName() + ';'));
        Observer.Observe('varIsTyped', Format(Echo = Typed + ';'));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Company_Exact()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := CompanyName();
        P.OpenEdit();
        if TrySet_CompF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('valueIsCompanyName', Format(P.CompF.Value() = CompanyName()));
        Observer.Observe('valueIsTyped', Format(P.CompF.Value() = Typed));
        P.EchoCompName.Invoke();
        Echo := Log.Take();
        Observer.Observe('varIsCompanyName', Format(Echo = CompanyName() + ';'));
        Observer.Observe('varIsTyped', Format(Echo = Typed + ';'));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Company_Blank()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := '';
        P.OpenEdit();
        if TrySet_CompF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('valueIsCompanyName', Format(P.CompF.Value() = CompanyName()));
        Observer.Observe('valueIsTyped', Format(P.CompF.Value() = Typed));
        P.EchoCompName.Invoke();
        Echo := Log.Take();
        Observer.Observe('varIsCompanyName', Format(Echo = CompanyName() + ';'));
        Observer.Observe('varIsTyped', Format(Echo = Typed + ';'));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Company_NoMatch()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'NO SUCH COMPANY 4711';
        P.OpenEdit();
        if TrySet_CompF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('valueIsCompanyName', Format(P.CompF.Value() = CompanyName()));
        Observer.Observe('valueIsTyped', Format(P.CompF.Value() = Typed));
        P.EchoCompName.Invoke();
        Echo := Log.Take();
        Observer.Observe('varIsCompanyName', Format(Echo = CompanyName() + ';'));
        Observer.Observe('varIsTyped', Format(Echo = Typed + ';'));
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TextKey_Upper()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'ALPHA BETA';
        P.OpenEdit();
        if TrySet_TextKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.TextKeyF.Value());
        P.EchoTextKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TextKey_Lower()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'alpha beta';
        P.OpenEdit();
        if TrySet_TextKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.TextKeyF.Value());
        P.EchoTextKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TextKey_Exact()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'Alpha Beta';
        P.OpenEdit();
        if TrySet_TextKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.TextKeyF.Value());
        P.EchoTextKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TextKey_UniquePrefix()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'Ome';
        P.OpenEdit();
        if TrySet_TextKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.TextKeyF.Value());
        P.EchoTextKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TextKey_AmbiguousPrefix()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'Alpha';
        P.OpenEdit();
        if TrySet_TextKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.TextKeyF.Value());
        P.EchoTextKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TextKey_NoMatch()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'Zeta';
        P.OpenEdit();
        if TrySet_TextKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.TextKeyF.Value());
        P.EchoTextKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TextKey_Blank()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := '';
        P.OpenEdit();
        if TrySet_TextKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.TextKeyF.Value());
        P.EchoTextKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NonKey_Upper()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'GAMMA DELTA';
        P.OpenEdit();
        if TrySet_NonKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.NonKeyF.Value());
        P.EchoTextNonKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure NonKey_NoMatch()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'Zeta';
        P.OpenEdit();
        if TrySet_NonKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.NonKeyF.Value());
        P.EchoTextNonKey.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Conditional_MatchOutsideCondition()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'alpha gamma';
        P.OpenEdit();
        if TrySet_CondF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.CondF.Value());
        P.EchoTextCond.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Conditional_Lower()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'alpha beta';
        P.OpenEdit();
        if TrySet_CondF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.CondF.Value());
        P.EchoTextCond.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CodeVar_Lower()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'alpha beta';
        P.OpenEdit();
        if TrySet_CodeVarF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.CodeVarF.Value());
        P.EchoCodeVar.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TextToCodeKey_Lower()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'code1';
        P.OpenEdit();
        if TrySet_CodeKeyF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.CodeKeyF.Value());
        P.EchoTextToCode.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Integer_Match()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := '5';
        P.OpenEdit();
        if TrySet_IntF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.IntF.Value());
        P.EchoIntVar.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Integer_NoMatch()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := '99';
        P.OpenEdit();
        if TrySet_IntF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.IntF.Value());
        P.EchoIntVar.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure OnLookup_Lower()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'alpha beta';
        P.OpenEdit();
        if TrySet_LookupF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.LookupF.Value());
        P.EchoWithLookup.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure TemporaryTable_Value()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
        Typed: Text;
        Echo: Text;
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Typed := 'alpha beta';
        P.OpenEdit();
        if TrySet_TempF(P, Typed) then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.TempF.Value());
        P.EchoTempRel.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure ExtensionVariable_Lower()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "TPL Rel Card";
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        P.OpenEdit();
        if TrySetExt(P, 'alpha beta') then
            Observer.Observe('set', 'ok')
        else
            Observer.ObserveError('set');
        Observer.Observe('value', P.ExtF.Value());
        P.EchoExtText.Invoke();
        Observer.Observe('var', Log.Take());
        P.Close();
        Observer.Finish();
    end;

    [Test]
    procedure RecField_Lower()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "TPL Rel Holder Card";
        Holder: Record "TPL Rel Holder";
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Holder.DeleteAll();
        Holder.Id := 'H1';
        Holder.Insert();
        H.OpenEdit();
        H.RelNameF.SetValue('alpha beta');
        Observer.Observe('value', H.RelNameF.Value());
        H.Close();
        Holder.Get('H1');
        Observer.Observe('stored', Holder.RelName);
        Observer.Finish();
    end;

    [Test]
    procedure RecField_NoMatch()
    var
        Observer: Codeunit "Probe Observer";
        H: TestPage "TPL Rel Holder Card";
        Holder: Record "TPL Rel Holder";
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Holder.DeleteAll();
        Holder.Id := 'H1';
        Holder.Insert();
        H.OpenEdit();
        asserterror H.RelNameF.SetValue('Zeta');
        Observer.ObserveError('set');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RelRequestPageHandler')]
    procedure RequestPage_Company_Upper()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Commit();
        Log.SetMode('CompUpper');
        Report.RunModal(Report::"TPL Rel Report", true, false);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('RelRequestPageHandler')]
    procedure RequestPage_TextKey_Lower()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Reset();
        ClearLastError();
        Seed();
        Commit();
        Log.SetMode('TextLower');
        Report.RunModal(Report::"TPL Rel Report", true, false);
        Observer.Observe('log', Log.Take());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySet_CompF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.CompF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySet_TextKeyF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.TextKeyF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySet_NonKeyF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.NonKeyF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySet_CondF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.CondF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySet_CodeVarF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.CodeVarF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySet_CodeKeyF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.CodeKeyF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySet_IntF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.IntF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySet_LookupF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.LookupF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySet_TempF(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.TempF.SetValue(NewValue);
    end;

    [TryFunction]
    local procedure TrySetExt(var P: TestPage "TPL Rel Card"; NewValue: Text)
    begin
        P.ExtF.SetValue(NewValue);
    end;

    local procedure Seed()
    var
        RelText: Record "TPL Rel Text";
        RelCode: Record "TPL Rel Code";
        RelInt: Record "TPL Rel Int";
    begin
        RelText.DeleteAll();
        RelCode.DeleteAll();
        RelInt.DeleteAll();
        AddText(RelText, 'Alpha Beta', 'Gamma Delta', 1);
        AddText(RelText, 'Alpha Gamma', 'Epsilon', 2);
        AddText(RelText, 'Omega', 'Psi', 1);
        RelCode."Code" := 'CODE1';
        RelCode.Insert();
        RelInt.Id := 5;
        RelInt.Insert();
    end;

    local procedure AddText(var RelText: Record "TPL Rel Text"; NewName: Text[30]; NewDescription: Text[50]; NewKind: Integer)
    begin
        RelText.Name := NewName;
        RelText.Description := NewDescription;
        RelText.Kind := NewKind;
        RelText.Insert();
    end;

    [RequestPageHandler]
    procedure RelRequestPageHandler(var RP: TestRequestPage "TPL Rel Report")
    begin
        case Log.Mode() of
            'CompUpper':
                RP.CompF.SetValue(UpperCase(CompanyName()));
            'TextLower':
                RP.TextKeyF.SetValue('alpha beta');
        end;
        RP.OK().Invoke();
    end;
}
