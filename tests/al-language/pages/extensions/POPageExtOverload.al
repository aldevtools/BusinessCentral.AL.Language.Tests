// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: self-contained table 69180, codeunit 69180 (log), page 69180, page extension 69180, codeunit 69181 (test)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// A page extension may declare a procedure with the SAME NAME as a base page procedure when the parameter types differ (an overload); it compiles
// (the same signature is AL0440, see tests/must-not-compile). The base page's triggers run first, then the extension's. From the extension:
// - Describe(5) (Integer) calls the BASE procedure, Describe('t') (Text) and Describe(true) (Boolean) call the extension's overloads;
// - Describe(1.5) (Decimal) resolves to the Integer overload of the base page and raises at run time (the value does not fit an Integer).
// From the base page, Describe(7) calls the base procedure.
// BC versions: 27.5

table 69180 "PO Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69180 "PO Log"
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

page 69180 "PO Base Page"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "PO Row";

    layout
    {
        area(Content)
        {
            repeater(R)
            {
                field(Id; Rec.Id) { }
            }
        }
    }

    trigger OnOpenPage()
    var
        Log: Codeunit "PO Log";
    begin
        Log.Add('base:Describe(Integer)=' + Describe(7));
        Log.Add('base:Same(Integer)=' + Same(7));
    end;

    procedure Describe(Value: Integer): Text
    begin
        exit('base-int-' + Format(Value));
    end;

    procedure Same(Value: Integer): Text
    begin
        exit('base-same-' + Format(Value));
    end;
}

pageextension 69180 "PO Ext Page" extends "PO Base Page"
{
    trigger OnOpenPage()
    var
        Log: Codeunit "PO Log";
    begin
        Log.Add('ext:Describe(Integer)=' + Describe(5));
        Log.Add('ext:Describe(Text)=' + Describe('t'));
        asserterror Log.Add('ext:Describe(Decimal)=' + Describe(1.5));
        Log.Add('ext:Describe(Decimal)=raised');
        ClearLastError();
        Log.Add('ext:Describe(Boolean)=' + Describe(true));
    end;

    procedure Describe(Value: Text): Text
    begin
        exit('ext-text-' + Value);
    end;

    procedure Describe(Value: Boolean): Text
    begin
        exit('ext-bool-' + Format(Value));
    end;
}

codeunit 69181 "PO Overload Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PageExtension_OverloadOfBaseProcedure_WhichIsCalled()
    var
        Pg: TestPage "PO Base Page";
        Log: Codeunit "PO Log";
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Pg.OpenView();
        Observer.Observe('log', Log.Take());
        Pg.Close();
        Observer.Expect('log', 'base:Describe(Integer)=base-int-7;base:Same(Integer)=base-same-7;ext:Describe(Integer)=base-int-5;ext:Describe(Text)=ext-text-t;ext:Describe(Decimal)=raised;ext:Describe(Boolean)=ext-bool-Yes;');
        Observer.Verify();
    end;
}
