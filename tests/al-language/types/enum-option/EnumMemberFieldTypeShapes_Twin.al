// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT EMF Line (97997) of AL Language XApp A, with the fields "G Kind" (enum LT EMF GKind of the global
//   namespace) and "Ext Kind" (EnumMemberFieldTypeShapes_Ext.al); LT EMF Kind (97055, EnumMemberFieldType_Twin.al).
// Namespace EmfTwin, whose own enums "LT EMF Kind" (EnumMemberFieldType_Twin.al, Production at ordinal 5) and
// "LT EMF GKind" (here, Production at ordinal 5) have the names of the enums of LT EMF Line.Kind and "G Kind" (Production
// at ordinal 1 in both). The code here names `Field::Production` where the file's own namespace finds the twin first: on a
// temporary record, on a field a table extension adds, on a field whose enum is in the global namespace, through Rec and
// the bare field name in a table extension and in a page.
// local object: the twin enum and the readers of EnumMemberFieldTypeShapes_Tests.al.

namespace ALLanguage.Coverage.EmfTwin;

using ALLanguage.Coverage.EmfData;

enum 97048 "LT EMF GKind"
{
    value(0; " ") { }
    value(5; Production) { }
}

codeunit 97048 "LT EMF Twin Shapes Reader"
{
    procedure TemporaryOrdinal(): Integer
    var
        Line: Record "LT EMF Line" temporary;
    begin
        Line.Kind := Line.Kind::Production;
        exit(Line.Kind.AsInteger());
    end;

    procedure ExtensionFieldOrdinal(): Integer
    var
        Line: Record "LT EMF Line";
    begin
        Line."Ext Kind" := Line."Ext Kind"::Production;
        exit(Line."Ext Kind".AsInteger());
    end;

    procedure GlobalEnumFieldOrdinal(): Integer
    var
        Line: Record "LT EMF Line";
    begin
        Line."G Kind" := Line."G Kind"::Production;
        exit(Line."G Kind".AsInteger());
    end;

    procedure RecInTableExtensionOrdinal(): Integer
    var
        Line: Record "LT EMF Line";
    begin
        exit(Line.EmfTwinRecOrdinal());
    end;

    procedure BareInTableExtensionOrdinal(): Integer
    var
        Line: Record "LT EMF Line";
    begin
        exit(Line.EmfTwinBareOrdinal());
    end;

    procedure RecInPageOrdinal(): Integer
    var
        TwinPage: Page "LT EMF Twin Page";
    begin
        exit(TwinPage.RecOrdinal());
    end;

    procedure BareInPageOrdinal(): Integer
    var
        TwinPage: Page "LT EMF Twin Page";
    begin
        exit(TwinPage.BareOrdinal());
    end;
}

tableextension 97048 "LT EMF Twin Line Ext" extends "LT EMF Line"
{
    procedure EmfTwinRecOrdinal(): Integer
    begin
        Rec.Kind := Rec.Kind::Production;
        exit(Rec.Kind.AsInteger());
    end;

    procedure EmfTwinBareOrdinal(): Integer
    begin
        Kind := Kind::Production;
        exit(Kind.AsInteger());
    end;
}

page 97048 "LT EMF Twin Page"
{
    PageType = Card;
    SourceTable = "LT EMF Line";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }

    procedure RecOrdinal(): Integer
    begin
        Rec.Kind := Rec.Kind::Production;
        exit(Rec.Kind.AsInteger());
    end;

    procedure BareOrdinal(): Integer
    begin
        Kind := Kind::Production;
        exit(Kind.AsInteger());
    end;
}
