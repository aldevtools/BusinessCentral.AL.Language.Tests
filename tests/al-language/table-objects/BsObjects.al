// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope (Cloud-compatible)
// Objects for the tests that corpus issue #668 (odd AL behavior leads, part C) items 76 to 107 added to existing test codeunits:
//   tableextension/TestTableExtFieldModify.al, TestTableExtKeysAndInitValue.al, TestTableExtFieldTableRelation.al, TestTableExtCrossApp.al,
//   tableextensiontrigger/TestTableExtensionTableTriggers_Tests.al, handlers/TestPageCaptionClass.al, pageext/W2ExtModify.al,
//   record/lt-relation-where-multi/RelationWhereMulti.al, record/lt-filters-keys-finds/P68I_TransferEnumOption.al.
// Object ids 83150 - 83165 (writer bs). Not a test codeunit file.
// Compile facts found while writing these objects (AL 30 compiler, runtimes 16.1, 17.1 and 18.0), all accepted:
//   Caption on a tableextension; a tableextension field name longer than 30 characters (warning AL0468 only); a tableextension key of base
//   fields only; SumIndexFields that mix base and extension fields (warning AL0836 only); modify(<field>) { TableRelation = ... } in a
//   tableextension; a table and a tableextension with the same object id; keys of 17 and 19 fields; two tableextensions of one table that
//   call each other's procedures and use each other's fields; a page extension global with the name of a base page global; a protected
//   Label variable in a page extension; `Rec.OptionField := 16` for an option with 6 members.

table 83150 "LT BS Base"
{
    DataClassification = SystemMetadata;
    // No Caption here: with Caption on both the table and its tableextension, an app with the TranslationFile feature does not compile
    // (AL0839, the two symbols share one XLIFF trans-unit id; must-not-compile case 1490).

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
        field(3; B; Decimal) { }
        field(4; Name; Text[30]) { }
        // Unconditional relation on the base table; LT BS Base Ext One adds another unconditional one with modify().
        field(5; Ref; Code[20]) { TableRelation = "LT BS Target A"; }
        field(6; Kind; Option) { OptionMembers = X,Y,Z; }
        // Conditional relation on the base table; LT BS Base Ext One adds a second condition with modify().
        field(7; Cond; Code[20]) { TableRelation = if (Kind = const(X)) "LT BS Target A"; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    procedure BaseProc(): Text
    begin
        exit('base:' + Format(Rec.Id));
    end;
}

table 83151 "LT BS Target A"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 83152 "LT BS Target B"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

tableextension 83150 "LT BS Base Ext One" extends "LT BS Base"
{
    Caption = 'LT BS Ext Caption';

    fields
    {
        field(83150; "LT BS Field Name Longer Than Thirty"; Integer) { DataClassification = SystemMetadata; }
        field(83151; E1; Integer) { DataClassification = SystemMetadata; }
        field(83152; E2; Decimal) { DataClassification = SystemMetadata; }
        modify(Ref) { TableRelation = "LT BS Target B"; }
        modify(Cond) { TableRelation = if (Kind = const(Y)) "LT BS Target B"; }
    }

    keys
    {
        key(BsBaseOnly; A, Name) { }
        key(BsExtSum; E1) { SumIndexFields = B, E2; }
    }

    procedure BsCallTwo(): Text
    begin
        // Uses a field and a procedure of LT BS Base Ext Two, the extension with the higher object id.
        Rec.E3 := Rec.Id * 10;
        exit('one>' + Rec.BsFromOne());
    end;

    procedure BsFromTwo(): Text
    begin
        exit('one:' + Format(Rec.E1));
    end;

    procedure BsRecToSink(): Text
    var
        Sink: Codeunit "LT BS Rec Sink";
    begin
        exit(Sink.Take(Rec));
    end;

    procedure BsFillArray(var Arr: array[3] of Text)
    begin
        Arr[1] := Rec.Name;
        Arr[2] := Format(Rec.Id);
        Arr[3] := Rec.BaseProc();
    end;

    trigger OnAfterModify()
    var
        Log: Codeunit "LT BS Ext Log";
    begin
        Log.Add('after modify xRec=' + xRec.Name + ' Rec=' + Rec.Name);
    end;
}

tableextension 83151 "LT BS Base Ext Two" extends "LT BS Base"
{
    fields
    {
        field(83160; E3; Integer) { DataClassification = SystemMetadata; }
    }

    procedure BsFromOne(): Text
    begin
        exit('two:' + Format(Rec.E3));
    end;

    procedure BsCallOne(): Text
    begin
        // Uses a field and a procedure of LT BS Base Ext One, the extension with the lower object id.
        Rec.E1 := Rec.Id + 1;
        exit('two>' + Rec.BsFromTwo());
    end;
}

// The same object id as tableextension 83153 below, which extends another table.
table 83153 "LT BS Same Id"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 83153 "LT BS Same Id Ext" extends "LT BS Target A"
{
    fields
    {
        field(83170; SameIdExt; Text[30]) { DataClassification = SystemMetadata; }
    }
}

table 83154 "LT BS Wide Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; F1; Integer) { }
        field(2; F2; Integer) { }
        field(3; F3; Integer) { }
        field(4; F4; Integer) { }
        field(5; F5; Integer) { }
        field(6; F6; Integer) { }
        field(7; F7; Integer) { }
        field(8; F8; Integer) { }
        field(9; F9; Integer) { }
        field(10; F10; Integer) { }
        field(11; F11; Integer) { }
        field(12; F12; Integer) { }
        field(13; F13; Integer) { }
        field(14; F14; Integer) { }
        field(15; F15; Integer) { }
        field(16; F16; Integer) { }
        field(17; F17; Integer) { }
        field(18; F18; Integer) { }
        field(19; F19; Integer) { }
        field(20; F20; Integer) { }
    }

    keys
    {
        key(PK; F1) { Clustered = true; }
        // 17 fields, and 19 fields; the docs say only the first 16 fields of a key are used.
        key(K17; F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18) { }
        key(K19; F20, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, F13, F14, F15, F16, F17, F18, F19, F2) { }
    }
}

table 83155 "LT BS NK Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 83156 "LT BS NK Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        // A relation to a field that is in no key of the target table.
        field(2; RefName; Text[30]) { TableRelation = "LT BS NK Target".Name; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 83157 "LT BS Opt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        // Six members, ordinals 0 to 5.
        field(2; Opt; Option) { OptionMembers = M0,M1,M2,M3,M4,M5; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 83163 "LT BS Rec Sink"
{
    procedure Take(var R: Record "LT BS Base"): Text
    begin
        exit(Format(R.Id) + ':' + R.Name + ':' + Format(R.E1));
    end;
}

codeunit 83164 "LT BS Ext Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += '|';
        Entries += Entry;
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

page 83161 "LT BS Card"
{
    PageType = Card;
    SourceTable = "LT BS Base";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; Visible = X; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    var
        // Never set: false. The page extension declares its own X and sets it to true.
        X: Boolean;
}

pageextension 83161 "LT BS Card Ext" extends "LT BS Card"
{
    layout
    {
        addlast(Content)
        {
            field(BsExtA; Rec.A) { ApplicationArea = All; Visible = X; }
        }
    }

    var
        X: Boolean;

    protected var
        BsProtectedTxt: Label 'LT BS protected label';

    trigger OnOpenPage()
    begin
        X := true;
    end;

    procedure BsGetProtectedLabel(): Text
    begin
        exit(BsProtectedTxt);
    end;
}

// Item 99: a field ADDED by a tableextension declares CaptionClass; the page extension shows it without a CaptionClass of its own.
tableextension 83160 "LT BS Tpcc Row Ext" extends "TPCC Row"
{
    fields
    {
        field(83180; BsCapNew; Text[30]) { CaptionClass = '3,LT BS Added Field Class'; Caption = 'LT BS Added Caption'; DataClassification = SystemMetadata; }
    }
}

pageextension 83162 "LT BS Tpcc Card Ext" extends "TPCC Card"
{
    layout
    {
        addlast(Content)
        {
            field(BsCapNew; Rec.BsCapNew) { ApplicationArea = All; }
            field(BsCapNewPageClass; Rec.BsCapNew) { ApplicationArea = All; CaptionClass = '3,LT BS Page Class'; }
        }
    }
}
