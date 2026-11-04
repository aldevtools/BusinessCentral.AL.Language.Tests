// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Fixtures used: addin/lt-p121.js, objects of this file. Also the interface with Scope = Cloud (issue 601.20)
// Objects of the issue 602 probes: every object kind and control kind with ObsoleteState = Pending, ObsoleteReason and ObsoleteTag. Pending code still compiles and runs; the tests
// are in UObsoletePending.al. Removed is not a value of ObsoleteState for these kinds (AL0169, see the must-not-compile cases).
// Object ids 69791 to 69798.

interface "LT U Obsolete Interface"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The interface is replaced.';
    ObsoleteTag = '27.0';

    procedure Answer(): Integer;
}

controladdin "LT U Obsolete AddIn"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The control add-in is replaced.';
    ObsoleteTag = '27.1';
    Scripts = 'controladdins/lt-p121.js';

    event Ready();
}

interface "LT U Scope Interface"
{
    Scope = Cloud;

    procedure Ping(): Integer;
}

codeunit 69791 "LT U Obsolete CU" implements "LT U Obsolete Interface", "LT U Scope Interface"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The codeunit is replaced.';
    ObsoleteTag = '27.2';

    procedure Answer(): Integer
    begin
        exit(42);
    end;

    procedure Ping(): Integer
    begin
        exit(7);
    end;
}

enum 69792 "LT U Obsolete Enum"
{
    Extensible = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'The enum is replaced.';
    ObsoleteTag = '27.3';

    value(0; Current) { }
    value(1; Old)
    {
        ObsoleteState = Pending;
        ObsoleteReason = 'The value is replaced.';
        ObsoleteTag = '27.4';
    }
}

enumextension 69793 "LT U Obsolete Enum Ext" extends "LT U Obsolete Enum"
{
    value(69793; ExtOld)
    {
        ObsoleteState = Pending;
        ObsoleteReason = 'The extension value is replaced.';
        ObsoleteTag = '27.5';
    }
    value(69794; ExtCurrent) { }
}

page 69794 "LT U Obsolete Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT U Page Src";
    ObsoleteState = Pending;
    ObsoleteReason = 'The page is replaced.';
    ObsoleteTag = '27.6';

    layout
    {
        area(Content)
        {
            group(ObsGroup)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The group is replaced.';
                ObsoleteTag = '27.7';

                field(InObsGroup; Rec.Txt) { }
            }
            cuegroup(ObsCue)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The cue group is replaced.';
                ObsoleteTag = '27.8';

                field(InObsCue; Rec.Id) { }
            }
            label(ObsLabel)
            {
                Caption = 'An obsolete label';
                ObsoleteState = Pending;
                ObsoleteReason = 'The label is replaced.';
                ObsoleteTag = '27.9';
            }
            usercontrol(ObsAddIn; "LT U Obsolete AddIn") { }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ObsAction)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The action is replaced.';
                ObsoleteTag = '27.10';

                trigger OnAction()
                begin
                end;
            }
            separator(ObsSeparator)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The separator is replaced.';
                ObsoleteTag = '27.11';
            }
        }
    }
}

pageextension 69795 "LT U Obsolete Page Ext" extends "LT U Obsolete Page"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The page extension is replaced.';
    ObsoleteTag = '27.12';

    layout
    {
        addlast(Content)
        {
            field(ObsExtField; Rec.Note)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The extension field is replaced.';
                ObsoleteTag = '27.13';
            }
            group(ObsExtGroup)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The extension group is replaced.';
                ObsoleteTag = '27.14';

                field(InObsExtGroup; Rec.Dec) { }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ObsExtAction)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'The extension action is replaced.';
                ObsoleteTag = '27.15';

                trigger OnAction()
                begin
                end;
            }
        }
    }
}

query 69796 "LT U Obsolete Query"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The query is replaced.';
    ObsoleteTag = '27.16';

    elements
    {
        dataitem(Src; "LT U Page Src")
        {
            column(Id; Id) { }
        }
    }
}

report 69797 "LT U Obsolete Report"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The report is replaced.';
    ObsoleteTag = '27.17';
    ProcessingOnly = true;
    UseRequestPage = false;

    trigger OnPreReport()
    var
        Row: Record "LT U Isolation Row";
    begin
        Row.Id := 100;
        Row.Note := 'obsolete report ran';
        Row.Insert();
    end;
}

xmlport 69798 "LT U Obsolete XmlPort"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The XmlPort is replaced.';
    ObsoleteTag = '27.18';
    Direction = Export;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Src; "LT U Page Src")
            {
                fieldelement(Id; Src.Id) { }
            }
        }
    }
}
