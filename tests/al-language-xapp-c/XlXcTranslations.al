// Objects of cross-app fixture C for the translation probe of a dependency app (al-runner area "translations", ADR-053 of the runner).
// Tests: tests/al-language/localization/app-xliff/TlTranslationCells.al (codeunit 96708).
// This app ships five translation files: Translations/AL Language XApp C.nl-BE.xlf, .nl-NL.xlf, .fr-FR.xlf, .en-GB.xlf and .en-US.xlf. Only the
// objects of this file have units in them, so every other text of this app keeps its source text in every language.
// Which file gives which unit (the targets name their file, so an observed text shows where it came from):
//   BothLbl     nl-BE 'Beide BE', nl-NL 'Beide NL', fr-FR 'Les deux FR', en-GB 'Both GB'
//   NlOnlyLbl   nl-NL 'Alleen NL'           (no unit in nl-BE)
//   BeOnlyLbl   nl-BE 'Alleen BE'           (no unit in nl-NL)
//   FrOnlyLbl   fr-FR 'Seulement FR'
//   GbOnlyLbl   en-GB 'Colour GB'
//   UsOnlyLbl   en-US 'Colour from the en-US file' (does BC read an en-US file under 1033?)
//   CrossLbl    no unit in this app's files; the main test app's nl-NL file has a unit with this label's id ('Kruis uit de hoofdapp')
//   enum "LT XL Kind": Alpha nl-BE 'Alfa BE', nl-NL 'Alfa NL', fr-FR 'Alpha FR'; Beta nl-NL 'Beta NL' only
//   table "LT XL Row": table caption nl-BE 'XL rij BE', nl-NL 'XL rij NL'; field Code nl-BE 'Rijcode BE', nl-NL 'Rijcode NL'
// local object: the translation files of this dependency app are the thing under test.

codeunit 61123 "LT XL Labels"
{
    var
        BothLbl: Label 'Both files';
        NlOnlyLbl: Label 'Only NL';
        BeOnlyLbl: Label 'Only BE';
        FrOnlyLbl: Label 'Only FR';
        GbOnlyLbl: Label 'Color';
        CrossLbl: Label 'Cross app';
        UsOnlyLbl: Label 'Color US';

    procedure Both(): Text
    begin
        exit(BothLbl);
    end;

    procedure NlOnly(): Text
    begin
        exit(NlOnlyLbl);
    end;

    procedure BeOnly(): Text
    begin
        exit(BeOnlyLbl);
    end;

    procedure FrOnly(): Text
    begin
        exit(FrOnlyLbl);
    end;

    procedure GbOnly(): Text
    begin
        exit(GbOnlyLbl);
    end;

    procedure Cross(): Text
    begin
        exit(CrossLbl);
    end;

    procedure UsOnly(): Text
    begin
        exit(UsOnlyLbl);
    end;
}

enum 61124 "LT XL Kind"
{
    Extensible = true;

    value(0; Alpha)
    {
        Caption = 'Alpha kind';
    }
    value(1; Beta)
    {
        Caption = 'Beta kind';
    }
}

table 61126 "LT XL Row"
{
    Caption = 'XL row';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Row code';
        }
        field(2; Kind; Enum "LT XL Kind")
        {
            Caption = 'Kind';
        }
    }
    keys
    {
        key(PK; "Code") { }
    }
}
