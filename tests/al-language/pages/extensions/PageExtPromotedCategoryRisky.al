// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 70646, pages 70647, page extension 70648, codeunits 70649 (log) and 70650 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "An extension adding to the implicit group of a legacy promoted category" (Page extension overload of a base page procedure ...)
// Facts: addlast(Category_Category4) / addfirst(Category_Category4) with an actionref in a page extension of a page whose action says Promoted = true; PromotedCategory = Category4;
//   the extension actions invoked from a TestPage and their state. RISKY: compile of Category_Category4 as an anchor is not known; keep in its own file.
// BC versions: 29 (27 and 28 by CI)

table 70646 "LT PCat Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70649 "LT PCat Log"
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
        R: Text;
    begin
        R := Entries;
        Entries := '';
        exit(R);
    end;
}

page 70647 "LT PCat Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT PCat Row";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BaseAct)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Category4;

                trigger OnAction()
                var
                    Log: Codeunit "LT PCat Log";
                begin
                    Log.Add('base');
                end;
            }
        }
    }
}

pageextension 70648 "LT PCat Ext" extends "LT PCat Card"
{
    actions
    {
        addlast(Processing)
        {
            action(ExtLast)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT PCat Log";
                begin
                    Log.Add('extlast');
                end;
            }
            action(ExtFirst)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT PCat Log";
                begin
                    Log.Add('extfirst');
                end;
            }
        }
        addlast(Category_Category4)
        {
            actionref(ExtLastRef; ExtLast) { }
        }
        addfirst(Category_Category4)
        {
            actionref(ExtFirstRef; ExtFirst) { }
        }
    }
}

codeunit 70650 "LT PCat Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P169_PromotedCategoryExtension_ActionsAreUsable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PCat Log";
        R: Record "LT PCat Row";
        P: TestPage "LT PCat Card";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Insert();
        Log.Take();
        P.OpenView();
        Observer.Observe('base_visible', Format(P.BaseAct.Visible()));
        Observer.Observe('base_enabled', Format(P.BaseAct.Enabled()));
        Observer.Observe('extlast_visible', Format(P.ExtLast.Visible()));
        Observer.Observe('extlast_enabled', Format(P.ExtLast.Enabled()));
        Observer.Observe('extfirst_visible', Format(P.ExtFirst.Visible()));
        Observer.Observe('extfirst_enabled', Format(P.ExtFirst.Enabled()));
        P.ExtLast.Invoke();
        P.ExtFirst.Invoke();
        P.BaseAct.Invoke();
        Observer.Observe('log', Log.Take());
        P.Close();
        Observer.Expect('base_visible', 'Yes');
        Observer.Expect('base_enabled', 'Yes');
        Observer.Expect('extlast_visible', 'Yes');
        Observer.Expect('extlast_enabled', 'Yes');
        Observer.Expect('extfirst_visible', 'Yes');
        Observer.Expect('extfirst_enabled', 'Yes');
        Observer.Expect('log', 'extlast;extfirst;base;');
        Observer.Verify();
    end;
}
