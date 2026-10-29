// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/pageextension/pageextension-onbeforevalidate-trigger
// Scope: in-scope
// Fixtures used: own table 90108, page 90109, pageextension 90110, manual subscriber codeunit 90111 (writer TT); tests TT_* in codeunit 60514
//   (TestModifiedControlValidateTriggers_Tests.al)
// The order of a pageextension modify() block's OnBeforeValidate / OnAfterValidate when the TABLE field has its own OnValidate too (the
// "MCV Card" suite pins it for a field without one): field Name has a table OnValidate and a page OnValidate, field Other a table
// OnValidate only. Codeunit 90111 (EventSubscriberInstance = Manual, bound by the tests that need it) adds the table's
// OnBeforeValidateEvent / OnAfterValidateEvent and the page's OnBeforeValidateEvent / OnAfterValidateEvent for both fields. Every trigger
// appends a tag to Rec.Trace.
// Probe: observed on the BC 29.0 SaaS sandbox; other versions by the corpus CI matrix.
// Facts (BC 29): table OnValidate runs FIRST, then the modify() OnBeforeValidate, the page control's OnValidate and OnAfterValidate. With
//   the events bound: table OnBeforeValidateEvent, table OnValidate, table OnAfterValidateEvent, page OnBeforeValidateEvent, modify()
//   OnBeforeValidate, page OnValidate, modify() OnAfterValidate, page OnAfterValidateEvent. Validate from code runs only the table part.
// BC versions: 27, 28, 29

table 90108 "LT TT MCV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50])
        {
            trigger OnValidate()
            begin
                Rec.Trace := Rec.Trace + 'table;';
            end;
        }
        field(3; Other; Text[50])
        {
            trigger OnValidate()
            begin
                Rec.Trace := Rec.Trace + 'othertable;';
            end;
        }
        field(5; Trace; Text[250]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 90109 "LT TT MCV Card"
{
    PageType = Card;
    SourceTable = "LT TT MCV Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id)
            {
                ApplicationArea = All;
            }
            field(Name; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    Rec.Trace := Rec.Trace + 'page;';
                end;
            }
            field(Other; Rec.Other)
            {
                ApplicationArea = All;
            }
            field(Trace; Rec.Trace)
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
}

pageextension 90110 "LT TT MCV Card Ext" extends "LT TT MCV Card"
{
    layout
    {
        modify(Name)
        {
            trigger OnBeforeValidate()
            begin
                Rec.Trace := Rec.Trace + 'before;';
            end;

            trigger OnAfterValidate()
            begin
                Rec.Trace := Rec.Trace + 'after;';
            end;
        }
        modify(Other)
        {
            trigger OnBeforeValidate()
            begin
                Rec.Trace := Rec.Trace + 'otherbefore;';
            end;

            trigger OnAfterValidate()
            begin
                Rec.Trace := Rec.Trace + 'otherafter;';
            end;
        }
    }
}

codeunit 90111 "LT TT MCV Subs"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT TT MCV Row", OnBeforeValidateEvent, Name, false, false)]
    local procedure TableBeforeName(var Rec: Record "LT TT MCV Row")
    begin
        Rec.Trace := Rec.Trace + 'tbefore;';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TT MCV Row", OnAfterValidateEvent, Name, false, false)]
    local procedure TableAfterName(var Rec: Record "LT TT MCV Row")
    begin
        Rec.Trace := Rec.Trace + 'tafter;';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TT MCV Row", OnBeforeValidateEvent, Other, false, false)]
    local procedure TableBeforeOther(var Rec: Record "LT TT MCV Row")
    begin
        Rec.Trace := Rec.Trace + 'othertbefore;';
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TT MCV Row", OnAfterValidateEvent, Other, false, false)]
    local procedure TableAfterOther(var Rec: Record "LT TT MCV Row")
    begin
        Rec.Trace := Rec.Trace + 'othertafter;';
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT TT MCV Card", OnBeforeValidateEvent, Name, false, false)]
    local procedure PageBeforeName(var Rec: Record "LT TT MCV Row")
    begin
        Rec.Trace := Rec.Trace + 'pbefore;';
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT TT MCV Card", OnAfterValidateEvent, Name, false, false)]
    local procedure PageAfterName(var Rec: Record "LT TT MCV Row")
    begin
        Rec.Trace := Rec.Trace + 'pafter;';
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT TT MCV Card", OnBeforeValidateEvent, Other, false, false)]
    local procedure PageBeforeOther(var Rec: Record "LT TT MCV Row")
    begin
        Rec.Trace := Rec.Trace + 'otherpbefore;';
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT TT MCV Card", OnAfterValidateEvent, Other, false, false)]
    local procedure PageAfterOther(var Rec: Record "LT TT MCV Row")
    begin
        Rec.Trace := Rec.Trace + 'otherpafter;';
    end;
}
