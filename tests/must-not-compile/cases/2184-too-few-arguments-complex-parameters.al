// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'V' of 'SigVariant(Integer, Variant)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'R' of 'SigRecordRef(Integer, RecordRef)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'F' of 'SigFieldRef(Integer, FieldRef)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'L' of 'SigList(Integer, List of [Text])'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'D' of 'SigDictionary(Integer, Dictionary of [Integer, Text])'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'C' of 'SigCodeunit(Integer, Codeunit "MNC SH Lib")'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'P' of 'SigPage(Integer, Page "MNC SH Page")'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'J' of 'SigJsonObject(Integer, JsonObject)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'A' of 'SigArray(Integer, array[3] of Integer)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'S' of 'SigSecretText(Integer, SecretText)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'I' of 'SigInterface(Integer, Interface "MNC SH Iface")'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'S' of 'SigInStream(Integer, InStream)'
// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'E' of 'SigErrorInfo(Integer, ErrorInfo)'
// The signature texts for Variant, RecordRef, FieldRef, List, Dictionary, Codeunit, Page, JsonObject, array, SecretText, Interface, InStream
// and ErrorInfo parameters (one call each).
table 50000 "MNC SH Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50003 "MNC SH Page"
{
    SourceTable = "MNC SH Table";
}

interface "MNC SH Iface"
{
    procedure DoIt();
}

codeunit 50001 "MNC SH Lib"
{
    procedure SigVariant(X: Integer; V: Variant)
    begin
    end;

    procedure SigRecordRef(X: Integer; R: RecordRef)
    begin
    end;

    procedure SigFieldRef(X: Integer; F: FieldRef)
    begin
    end;

    procedure SigList(X: Integer; L: List of [Text])
    begin
    end;

    procedure SigDictionary(X: Integer; D: Dictionary of [Integer, Text])
    begin
    end;

    procedure SigCodeunit(X: Integer; C: Codeunit "MNC SH Lib")
    begin
    end;

    procedure SigPage(X: Integer; P: Page "MNC SH Page")
    begin
    end;

    procedure SigJsonObject(X: Integer; J: JsonObject)
    begin
    end;

    procedure SigArray(X: Integer; A: array[3] of Integer)
    begin
    end;

    procedure SigSecretText(X: Integer; S: SecretText)
    begin
    end;

    procedure SigInterface(X: Integer; I: Interface "MNC SH Iface")
    begin
    end;

    procedure SigInStream(X: Integer; S: InStream)
    begin
    end;

    procedure SigErrorInfo(X: Integer; E: ErrorInfo)
    begin
    end;
}

codeunit 50002 "MNC SH Caller"
{
    procedure Run1()
    var
        Lib: Codeunit "MNC SH Lib";
    begin
        Lib.SigVariant(1);
        Lib.SigRecordRef(1);
        Lib.SigFieldRef(1);
        Lib.SigList(1);
        Lib.SigDictionary(1);
        Lib.SigCodeunit(1);
        Lib.SigPage(1);
        Lib.SigJsonObject(1);
        Lib.SigArray(1);
        Lib.SigSecretText(1);
        Lib.SigInterface(1);
        Lib.SigInStream(1);
        Lib.SigErrorInfo(1);
    end;
}
