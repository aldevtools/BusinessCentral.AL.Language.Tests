// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 96280-96283 (LT EL Row, LT EL Status, LT EL Eval)
// Probe: from al-runner issue 6924 (waldo): under GlobalLanguage 2067 (nl-BE) Evaluate(BoolVar, 'Ja') succeeds on BC and Format(BoolVar, 0, 9) is 'true'.
//   For GlobalLanguage 2067, 1043, 1031, 1036, 1030 and 1033: which texts Evaluate accepts into a Boolean (Yes, yes, No, true, False, 1, 0, Ja, ja, JA,
//   Nee, Nein, Nej, Oui, Non, Y, N), the error text and code of a rejected one, Format(Bool) and Format(Bool, 0, 9); Evaluate into an Option field and
//   an Enum (name, caption, caption under the language, ordinal) and their Format; Evaluate of date texts and Format(Date) and Format(Date, 0, 9).
// Facts (identical on BC 27.5, 28.5 and 29.0, W1 containers): see the pinned values; summary in corpus PR 1173.
// Blank first enum member (al-runner issue 6924, waldo run 2; WA_BlankEnum1/2/3_<language>_<id> at the end of the file, enums 97270 to 97272, GlobalLanguage 1034, 2067
// and 1033): a member named " " (with and without Caption ' '), and a member with an empty name. Measured on BC 27.5, 28.5 and 29.0 (identical, and identical in the three
// languages): Format of the blank member is ' ' for the " " members and '0' for the empty-name member; Format(blank, 0, 9) and Format(blank, 0, 2) are '0'. Evaluate of the text
// Format gave, of an empty text, of one or two blanks and of the ordinal '0' returns true and selects the blank member (ordinal 0), also when the start value was another
// member. The member names (First) and the caption of the current language are accepted; the captions of the other languages and the English caption under another
// language are rejected (Evaluate answers false with no error text, and the variable keeps its value).
// BC versions: 27+ (tested by the corpus CI matrix)

table 96280 "LT EL Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; State; Option)
        {
            OptionMembers = Open,Closed;
            OptionCaptionML = ENU = 'Open cap,Closed cap', NLB = 'Open BE,Gesloten BE', NLD = 'Open NL,Gesloten NL', DEU = 'Offen,Geschlossen', FRA = 'Ouvert,Ferme', DAN = 'Aaben,Lukket';
        }
        field(3; Flag; Boolean) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

enum 96281 "LT EL Status"
{
    Extensible = true;

    value(0; Open)
    {
        CaptionML = ENU = 'Open cap', NLB = 'Open BE', NLD = 'Open NL', DEU = 'Offen', FRA = 'Ouvert', DAN = 'Aaben';
    }
    value(1; Closed)
    {
        CaptionML = ENU = 'Closed cap', NLB = 'Gesloten BE', NLD = 'Gesloten NL', DEU = 'Geschlossen', FRA = 'Ferme', DAN = 'Lukket';
    }
}

codeunit 96282 "LT EL Eval"
{
    [TryFunction]
    procedure TryBool(Word: Text)
    var
        B: Boolean;
    begin
        Evaluate(B, Word);
    end;
}

codeunit 96283 "LT EL Evaluate Language"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Words(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        B: Boolean;
        WordList: List of [Text];
        Word: Text;
        Result: Text;
    begin
        GlobalLanguage(Lang);
        WordList.AddRange('Yes', 'yes', 'No', 'true', 'False', '1', '0', 'Ja', 'ja', 'JA', 'Nee', 'Nein', 'Nej', 'Oui', 'Non', 'Y', 'N', ' Ja ');
        foreach Word in WordList do begin
            B := false;
            if Evaluate(B, Word) then
                Result := 'ok|' + Format(B, 0, 9)
            else
                Result := 'rejected';
            Observer.Observe('Evaluate ' + Word, Result);
        end;
        GlobalLanguage(1033);
    end;

    local procedure RunWords(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    begin
        Words(Observer, Lang);
    end;

    local procedure RunErrors(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Eval: Codeunit "LT EL Eval";
        B: Boolean;
        WordList: List of [Text];
        Word: Text;
    begin
        GlobalLanguage(Lang);
        WordList.AddRange('Yes', 'Ja', 'Oui');
        foreach Word in WordList do begin
            ClearLastError();
            if Eval.TryBool(Word) then
                Observer.Observe('TryBool ' + Word, 'ok')
            else begin
                Observer.Observe('TryBool ' + Word, 'err');
                Observer.ObserveError('TryBool ' + Word);
            end;
        end;
        B := true;
        Observer.Observe('Format true', Format(B));
        Observer.Observe('Format true 0 9', Format(B, 0, 9));
        Observer.Observe('Format true 1 9', Format(B, 1, 9));
        B := false;
        Observer.Observe('Format false', Format(B));
        Observer.Observe('Format false 0 9', Format(B, 0, 9));
        Observer.Observe('Format false 0 1', Format(B, 0, 1));
        Observer.Observe('Format true 0 2', Format(true, 0, 2));
        GlobalLanguage(1033);
    end;

    local procedure RunOption(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Row: Record "LT EL Row";
        WordList: List of [Text];
        Word: Text;
        Result: Text;
    begin
        GlobalLanguage(Lang);
        WordList.AddRange('Open', 'open', 'Closed', 'Open cap', 'Open BE', 'Gesloten BE', 'Gesloten NL', 'gesloten nl', 'Offen', 'offen', 'Geschlossen', 'Ouvert', 'Ferme', 'Aaben', 'Lukket', '1');
        foreach Word in WordList do begin
            Row.State := Row.State::Open;
            if Evaluate(Row.State, Word) then
                Result := 'ok|' + Format(Row.State, 0, 2)
            else
                Result := 'rejected';
            Observer.Observe('Option ' + Word, Result);
        end;
        Row.State := Row.State::Closed;
        Observer.Observe('Format Closed', Format(Row.State));
        Observer.Observe('Format Closed 0 9', Format(Row.State, 0, 9));
        Observer.Observe('Format Closed 0 2', Format(Row.State, 0, 2));
        GlobalLanguage(1033);
    end;

    local procedure RunEnum(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Status: Enum "LT EL Status";
        WordList: List of [Text];
        Word: Text;
        Result: Text;
    begin
        GlobalLanguage(Lang);
        WordList.AddRange('Open', 'open', 'Closed', 'Open cap', 'Open BE', 'Gesloten BE', 'Gesloten NL', 'Offen', 'Geschlossen', 'Ouvert', 'Ferme', 'Aaben', 'Lukket', '1');
        foreach Word in WordList do begin
            Status := Status::Open;
            if Evaluate(Status, Word) then
                Result := 'ok|' + Format(Status, 0, 2)
            else
                Result := 'rejected';
            Observer.Observe('Enum ' + Word, Result);
        end;
        Status := Status::Closed;
        Observer.Observe('Format Closed', Format(Status));
        Observer.Observe('Format Closed 0 9', Format(Status, 0, 9));
        Observer.Observe('Format Closed 0 2', Format(Status, 0, 2));
        GlobalLanguage(1033);
    end;

    local procedure RunDate(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        D: Date;
        WordList: List of [Text];
        Word: Text;
        Result: Text;
    begin
        GlobalLanguage(Lang);
        WordList.AddRange('31.12.2026', '31/12/2026', '12/31/2026', '31-12-2026', '31-12-26', '2026-12-31', '311226', '31 december 2026', '31 Dezember 2026', '31. Dezember 2026', 'Dec 31 2026');
        foreach Word in WordList do begin
            D := 0D;
            if Evaluate(D, Word) then
                Result := 'ok|' + Format(D, 0, 9)
            else
                Result := 'rejected';
            Observer.Observe('Date ' + Word, Result);
        end;
        D := DMY2Date(31, 12, 2026);
        Observer.Observe('Format date', Format(D));
        Observer.Observe('Format date 0 9', Format(D, 0, 9));
        Observer.Observe('Format date 0 4', Format(D, 0, 4));
        Observer.Observe('Format date 0 0', Format(D, 0, 0));
        GlobalLanguage(1033);
    end;

    [Test]
    procedure EL_Words_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 2067);
        Observer.Expect('Evaluate Yes', 'rejected');
        Observer.Expect('Evaluate yes', 'rejected');
        Observer.Expect('Evaluate No', 'rejected');
        Observer.Expect('Evaluate true', 'ok|true');
        Observer.Expect('Evaluate False', 'ok|false');
        Observer.Expect('Evaluate 1', 'ok|true');
        Observer.Expect('Evaluate 0', 'ok|false');
        Observer.Expect('Evaluate Ja', 'ok|true');
        Observer.Expect('Evaluate ja', 'ok|true');
        Observer.Expect('Evaluate JA', 'ok|true');
        Observer.Expect('Evaluate Nee', 'ok|false');
        Observer.Expect('Evaluate Nein', 'rejected');
        Observer.Expect('Evaluate Nej', 'rejected');
        Observer.Expect('Evaluate Oui', 'rejected');
        Observer.Expect('Evaluate Non', 'rejected');
        Observer.Expect('Evaluate Y', 'rejected');
        Observer.Expect('Evaluate N', 'ok|false');
        Observer.Expect('Evaluate  Ja ', 'ok|true');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Errors_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 2067);
        Observer.Expect('TryBool Yes', 'err');
        Observer.Expect('TryBool Yes|text', 'De waarde "Yes" kan niet worden geëvalueerd tot type Boolean.');
        Observer.Expect('TryBool Yes|code', 'Evaluate');
        Observer.Expect('TryBool Ja', 'ok');
        Observer.Expect('TryBool Oui', 'err');
        Observer.Expect('TryBool Oui|text', 'De waarde "Oui" kan niet worden geëvalueerd tot type Boolean.');
        Observer.Expect('TryBool Oui|code', 'Evaluate');
        Observer.Expect('Format true', 'Ja');
        Observer.Expect('Format true 0 9', 'true');
        Observer.Expect('Format true 1 9', 't');
        Observer.Expect('Format false', 'Nee');
        Observer.Expect('Format false 0 9', 'false');
        Observer.Expect('Format false 0 1', 'Nee');
        Observer.Expect('Format true 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Option_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 2067);
        Observer.Expect('Option Open', 'ok|0');
        Observer.Expect('Option open', 'ok|0');
        Observer.Expect('Option Closed', 'ok|1');
        Observer.Expect('Option Open cap', 'rejected');
        Observer.Expect('Option Open BE', 'ok|0');
        Observer.Expect('Option Gesloten BE', 'ok|1');
        Observer.Expect('Option Gesloten NL', 'rejected');
        Observer.Expect('Option gesloten nl', 'rejected');
        Observer.Expect('Option Offen', 'rejected');
        Observer.Expect('Option offen', 'rejected');
        Observer.Expect('Option Geschlossen', 'rejected');
        Observer.Expect('Option Ouvert', 'rejected');
        Observer.Expect('Option Ferme', 'rejected');
        Observer.Expect('Option Aaben', 'rejected');
        Observer.Expect('Option Lukket', 'rejected');
        Observer.Expect('Option 1', 'ok|1');
        Observer.Expect('Format Closed', 'Gesloten BE');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Enum_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 2067);
        Observer.Expect('Enum Open', 'ok|0');
        Observer.Expect('Enum open', 'ok|0');
        Observer.Expect('Enum Closed', 'ok|1');
        Observer.Expect('Enum Open cap', 'rejected');
        Observer.Expect('Enum Open BE', 'ok|0');
        Observer.Expect('Enum Gesloten BE', 'ok|1');
        Observer.Expect('Enum Gesloten NL', 'rejected');
        Observer.Expect('Enum Offen', 'rejected');
        Observer.Expect('Enum Geschlossen', 'rejected');
        Observer.Expect('Enum Ouvert', 'rejected');
        Observer.Expect('Enum Ferme', 'rejected');
        Observer.Expect('Enum Aaben', 'rejected');
        Observer.Expect('Enum Lukket', 'rejected');
        Observer.Expect('Enum 1', 'ok|1');
        Observer.Expect('Format Closed', 'Gesloten BE');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Date_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 2067);
        Observer.Expect('Date 31.12.2026', 'rejected');
        Observer.Expect('Date 31/12/2026', 'rejected');
        Observer.Expect('Date 12/31/2026', 'ok|2026-12-31');
        Observer.Expect('Date 31-12-2026', 'rejected');
        Observer.Expect('Date 31-12-26', 'rejected');
        Observer.Expect('Date 2026-12-31', 'ok|2026-12-31');
        Observer.Expect('Date 311226', 'rejected');
        Observer.Expect('Date 31 december 2026', 'ok|2026-12-31');
        Observer.Expect('Date 31 Dezember 2026', 'rejected');
        Observer.Expect('Date 31. Dezember 2026', 'rejected');
        Observer.Expect('Date Dec 31 2026', 'rejected');
        Observer.Expect('Format date', '12/31/26');
        Observer.Expect('Format date 0 9', '2026-12-31');
        Observer.Expect('Format date 0 4', 'december 31, 2026');
        Observer.Expect('Format date 0 0', '12/31/26');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Words_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1043);
        Observer.Expect('Evaluate Yes', 'rejected');
        Observer.Expect('Evaluate yes', 'rejected');
        Observer.Expect('Evaluate No', 'rejected');
        Observer.Expect('Evaluate true', 'ok|true');
        Observer.Expect('Evaluate False', 'ok|false');
        Observer.Expect('Evaluate 1', 'ok|true');
        Observer.Expect('Evaluate 0', 'ok|false');
        Observer.Expect('Evaluate Ja', 'ok|true');
        Observer.Expect('Evaluate ja', 'ok|true');
        Observer.Expect('Evaluate JA', 'ok|true');
        Observer.Expect('Evaluate Nee', 'ok|false');
        Observer.Expect('Evaluate Nein', 'rejected');
        Observer.Expect('Evaluate Nej', 'rejected');
        Observer.Expect('Evaluate Oui', 'rejected');
        Observer.Expect('Evaluate Non', 'rejected');
        Observer.Expect('Evaluate Y', 'rejected');
        Observer.Expect('Evaluate N', 'ok|false');
        Observer.Expect('Evaluate  Ja ', 'ok|true');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Errors_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1043);
        Observer.Expect('TryBool Yes', 'err');
        Observer.Expect('TryBool Yes|text', 'De waarde "Yes" kan niet worden geëvalueerd tot type Boolean.');
        Observer.Expect('TryBool Yes|code', 'Evaluate');
        Observer.Expect('TryBool Ja', 'ok');
        Observer.Expect('TryBool Oui', 'err');
        Observer.Expect('TryBool Oui|text', 'De waarde "Oui" kan niet worden geëvalueerd tot type Boolean.');
        Observer.Expect('TryBool Oui|code', 'Evaluate');
        Observer.Expect('Format true', 'Ja');
        Observer.Expect('Format true 0 9', 'true');
        Observer.Expect('Format true 1 9', 't');
        Observer.Expect('Format false', 'Nee');
        Observer.Expect('Format false 0 9', 'false');
        Observer.Expect('Format false 0 1', 'Nee');
        Observer.Expect('Format true 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Option_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1043);
        Observer.Expect('Option Open', 'ok|0');
        Observer.Expect('Option open', 'ok|0');
        Observer.Expect('Option Closed', 'ok|1');
        Observer.Expect('Option Open cap', 'rejected');
        Observer.Expect('Option Open BE', 'rejected');
        Observer.Expect('Option Gesloten BE', 'rejected');
        Observer.Expect('Option Gesloten NL', 'ok|1');
        Observer.Expect('Option gesloten nl', 'ok|1');
        Observer.Expect('Option Offen', 'rejected');
        Observer.Expect('Option offen', 'rejected');
        Observer.Expect('Option Geschlossen', 'rejected');
        Observer.Expect('Option Ouvert', 'rejected');
        Observer.Expect('Option Ferme', 'rejected');
        Observer.Expect('Option Aaben', 'rejected');
        Observer.Expect('Option Lukket', 'rejected');
        Observer.Expect('Option 1', 'ok|1');
        Observer.Expect('Format Closed', 'Gesloten NL');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Enum_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1043);
        Observer.Expect('Enum Open', 'ok|0');
        Observer.Expect('Enum open', 'ok|0');
        Observer.Expect('Enum Closed', 'ok|1');
        Observer.Expect('Enum Open cap', 'rejected');
        Observer.Expect('Enum Open BE', 'rejected');
        Observer.Expect('Enum Gesloten BE', 'rejected');
        Observer.Expect('Enum Gesloten NL', 'ok|1');
        Observer.Expect('Enum Offen', 'rejected');
        Observer.Expect('Enum Geschlossen', 'rejected');
        Observer.Expect('Enum Ouvert', 'rejected');
        Observer.Expect('Enum Ferme', 'rejected');
        Observer.Expect('Enum Aaben', 'rejected');
        Observer.Expect('Enum Lukket', 'rejected');
        Observer.Expect('Enum 1', 'ok|1');
        Observer.Expect('Format Closed', 'Gesloten NL');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Date_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1043);
        Observer.Expect('Date 31.12.2026', 'rejected');
        Observer.Expect('Date 31/12/2026', 'rejected');
        Observer.Expect('Date 12/31/2026', 'ok|2026-12-31');
        Observer.Expect('Date 31-12-2026', 'rejected');
        Observer.Expect('Date 31-12-26', 'rejected');
        Observer.Expect('Date 2026-12-31', 'ok|2026-12-31');
        Observer.Expect('Date 311226', 'rejected');
        Observer.Expect('Date 31 december 2026', 'ok|2026-12-31');
        Observer.Expect('Date 31 Dezember 2026', 'rejected');
        Observer.Expect('Date 31. Dezember 2026', 'rejected');
        Observer.Expect('Date Dec 31 2026', 'rejected');
        Observer.Expect('Format date', '12/31/26');
        Observer.Expect('Format date 0 9', '2026-12-31');
        Observer.Expect('Format date 0 4', 'december 31, 2026');
        Observer.Expect('Format date 0 0', '12/31/26');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Words_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1031);
        Observer.Expect('Evaluate Yes', 'rejected');
        Observer.Expect('Evaluate yes', 'rejected');
        Observer.Expect('Evaluate No', 'rejected');
        Observer.Expect('Evaluate true', 'ok|true');
        Observer.Expect('Evaluate False', 'ok|false');
        Observer.Expect('Evaluate 1', 'ok|true');
        Observer.Expect('Evaluate 0', 'ok|false');
        Observer.Expect('Evaluate Ja', 'ok|true');
        Observer.Expect('Evaluate ja', 'ok|true');
        Observer.Expect('Evaluate JA', 'ok|true');
        Observer.Expect('Evaluate Nee', 'rejected');
        Observer.Expect('Evaluate Nein', 'ok|false');
        Observer.Expect('Evaluate Nej', 'rejected');
        Observer.Expect('Evaluate Oui', 'rejected');
        Observer.Expect('Evaluate Non', 'rejected');
        Observer.Expect('Evaluate Y', 'rejected');
        Observer.Expect('Evaluate N', 'ok|false');
        Observer.Expect('Evaluate  Ja ', 'ok|true');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Errors_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1031);
        Observer.Expect('TryBool Yes', 'err');
        Observer.Expect('TryBool Yes|text', 'Der Wert „Yes“ kann nicht in Typ Boolean ausgewertet werden.');
        Observer.Expect('TryBool Yes|code', 'Evaluate');
        Observer.Expect('TryBool Ja', 'ok');
        Observer.Expect('TryBool Oui', 'err');
        Observer.Expect('TryBool Oui|text', 'Der Wert „Oui“ kann nicht in Typ Boolean ausgewertet werden.');
        Observer.Expect('TryBool Oui|code', 'Evaluate');
        Observer.Expect('Format true', 'Ja');
        Observer.Expect('Format true 0 9', 'true');
        Observer.Expect('Format true 1 9', 't');
        Observer.Expect('Format false', 'Nein');
        Observer.Expect('Format false 0 9', 'false');
        Observer.Expect('Format false 0 1', 'Nein');
        Observer.Expect('Format true 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Option_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1031);
        Observer.Expect('Option Open', 'ok|0');
        Observer.Expect('Option open', 'ok|0');
        Observer.Expect('Option Closed', 'ok|1');
        Observer.Expect('Option Open cap', 'rejected');
        Observer.Expect('Option Open BE', 'rejected');
        Observer.Expect('Option Gesloten BE', 'rejected');
        Observer.Expect('Option Gesloten NL', 'rejected');
        Observer.Expect('Option gesloten nl', 'rejected');
        Observer.Expect('Option Offen', 'ok|0');
        Observer.Expect('Option offen', 'ok|0');
        Observer.Expect('Option Geschlossen', 'ok|1');
        Observer.Expect('Option Ouvert', 'rejected');
        Observer.Expect('Option Ferme', 'rejected');
        Observer.Expect('Option Aaben', 'rejected');
        Observer.Expect('Option Lukket', 'rejected');
        Observer.Expect('Option 1', 'ok|1');
        Observer.Expect('Format Closed', 'Geschlossen');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Enum_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1031);
        Observer.Expect('Enum Open', 'ok|0');
        Observer.Expect('Enum open', 'ok|0');
        Observer.Expect('Enum Closed', 'ok|1');
        Observer.Expect('Enum Open cap', 'rejected');
        Observer.Expect('Enum Open BE', 'rejected');
        Observer.Expect('Enum Gesloten BE', 'rejected');
        Observer.Expect('Enum Gesloten NL', 'rejected');
        Observer.Expect('Enum Offen', 'ok|0');
        Observer.Expect('Enum Geschlossen', 'ok|1');
        Observer.Expect('Enum Ouvert', 'rejected');
        Observer.Expect('Enum Ferme', 'rejected');
        Observer.Expect('Enum Aaben', 'rejected');
        Observer.Expect('Enum Lukket', 'rejected');
        Observer.Expect('Enum 1', 'ok|1');
        Observer.Expect('Format Closed', 'Geschlossen');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Date_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1031);
        Observer.Expect('Date 31.12.2026', 'rejected');
        Observer.Expect('Date 31/12/2026', 'rejected');
        Observer.Expect('Date 12/31/2026', 'ok|2026-12-31');
        Observer.Expect('Date 31-12-2026', 'rejected');
        Observer.Expect('Date 31-12-26', 'rejected');
        Observer.Expect('Date 2026-12-31', 'ok|2026-12-31');
        Observer.Expect('Date 311226', 'rejected');
        Observer.Expect('Date 31 december 2026', 'ok|2026-12-31');
        Observer.Expect('Date 31 Dezember 2026', 'rejected');
        Observer.Expect('Date 31. Dezember 2026', 'rejected');
        Observer.Expect('Date Dec 31 2026', 'rejected');
        Observer.Expect('Format date', '12/31/26');
        Observer.Expect('Format date 0 9', '2026-12-31');
        Observer.Expect('Format date 0 4', 'Dezember 31, 2026');
        Observer.Expect('Format date 0 0', '12/31/26');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Words_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1036);
        Observer.Expect('Evaluate Yes', 'rejected');
        Observer.Expect('Evaluate yes', 'rejected');
        Observer.Expect('Evaluate No', 'ok|false');
        Observer.Expect('Evaluate true', 'ok|true');
        Observer.Expect('Evaluate False', 'ok|false');
        Observer.Expect('Evaluate 1', 'ok|true');
        Observer.Expect('Evaluate 0', 'ok|false');
        Observer.Expect('Evaluate Ja', 'rejected');
        Observer.Expect('Evaluate ja', 'rejected');
        Observer.Expect('Evaluate JA', 'rejected');
        Observer.Expect('Evaluate Nee', 'rejected');
        Observer.Expect('Evaluate Nein', 'rejected');
        Observer.Expect('Evaluate Nej', 'rejected');
        Observer.Expect('Evaluate Oui', 'ok|true');
        Observer.Expect('Evaluate Non', 'ok|false');
        Observer.Expect('Evaluate Y', 'rejected');
        Observer.Expect('Evaluate N', 'ok|false');
        Observer.Expect('Evaluate  Ja ', 'rejected');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Errors_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1036);
        Observer.Expect('TryBool Yes', 'err');
        Observer.Expect('TryBool Yes|text', 'La valeur « Yes » ne peut pas être évaluée en type Boolean.');
        Observer.Expect('TryBool Yes|code', 'Evaluate');
        Observer.Expect('TryBool Ja', 'err');
        Observer.Expect('TryBool Ja|text', 'La valeur « Ja » ne peut pas être évaluée en type Boolean.');
        Observer.Expect('TryBool Ja|code', 'Evaluate');
        Observer.Expect('TryBool Oui', 'ok');
        Observer.Expect('Format true', 'Oui');
        Observer.Expect('Format true 0 9', 'true');
        Observer.Expect('Format true 1 9', 't');
        Observer.Expect('Format false', 'Non');
        Observer.Expect('Format false 0 9', 'false');
        Observer.Expect('Format false 0 1', 'Non');
        Observer.Expect('Format true 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Option_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1036);
        Observer.Expect('Option Open', 'ok|0');
        Observer.Expect('Option open', 'ok|0');
        Observer.Expect('Option Closed', 'ok|1');
        Observer.Expect('Option Open cap', 'rejected');
        Observer.Expect('Option Open BE', 'rejected');
        Observer.Expect('Option Gesloten BE', 'rejected');
        Observer.Expect('Option Gesloten NL', 'rejected');
        Observer.Expect('Option gesloten nl', 'rejected');
        Observer.Expect('Option Offen', 'rejected');
        Observer.Expect('Option offen', 'rejected');
        Observer.Expect('Option Geschlossen', 'rejected');
        Observer.Expect('Option Ouvert', 'ok|0');
        Observer.Expect('Option Ferme', 'ok|1');
        Observer.Expect('Option Aaben', 'rejected');
        Observer.Expect('Option Lukket', 'rejected');
        Observer.Expect('Option 1', 'ok|1');
        Observer.Expect('Format Closed', 'Ferme');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Enum_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1036);
        Observer.Expect('Enum Open', 'ok|0');
        Observer.Expect('Enum open', 'ok|0');
        Observer.Expect('Enum Closed', 'ok|1');
        Observer.Expect('Enum Open cap', 'rejected');
        Observer.Expect('Enum Open BE', 'rejected');
        Observer.Expect('Enum Gesloten BE', 'rejected');
        Observer.Expect('Enum Gesloten NL', 'rejected');
        Observer.Expect('Enum Offen', 'rejected');
        Observer.Expect('Enum Geschlossen', 'rejected');
        Observer.Expect('Enum Ouvert', 'ok|0');
        Observer.Expect('Enum Ferme', 'ok|1');
        Observer.Expect('Enum Aaben', 'rejected');
        Observer.Expect('Enum Lukket', 'rejected');
        Observer.Expect('Enum 1', 'ok|1');
        Observer.Expect('Format Closed', 'Ferme');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Date_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1036);
        Observer.Expect('Date 31.12.2026', 'rejected');
        Observer.Expect('Date 31/12/2026', 'rejected');
        Observer.Expect('Date 12/31/2026', 'ok|2026-12-31');
        Observer.Expect('Date 31-12-2026', 'rejected');
        Observer.Expect('Date 31-12-26', 'rejected');
        Observer.Expect('Date 2026-12-31', 'ok|2026-12-31');
        Observer.Expect('Date 311226', 'rejected');
        Observer.Expect('Date 31 december 2026', 'ok|2026-12-31');
        Observer.Expect('Date 31 Dezember 2026', 'rejected');
        Observer.Expect('Date 31. Dezember 2026', 'rejected');
        Observer.Expect('Date Dec 31 2026', 'rejected');
        Observer.Expect('Format date', '12/31/26');
        Observer.Expect('Format date 0 9', '2026-12-31');
        Observer.Expect('Format date 0 4', 'décembre 31, 2026');
        Observer.Expect('Format date 0 0', '12/31/26');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Words_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1030);
        Observer.Expect('Evaluate Yes', 'rejected');
        Observer.Expect('Evaluate yes', 'rejected');
        Observer.Expect('Evaluate No', 'rejected');
        Observer.Expect('Evaluate true', 'ok|true');
        Observer.Expect('Evaluate False', 'ok|false');
        Observer.Expect('Evaluate 1', 'ok|true');
        Observer.Expect('Evaluate 0', 'ok|false');
        Observer.Expect('Evaluate Ja', 'ok|true');
        Observer.Expect('Evaluate ja', 'ok|true');
        Observer.Expect('Evaluate JA', 'ok|true');
        Observer.Expect('Evaluate Nee', 'rejected');
        Observer.Expect('Evaluate Nein', 'rejected');
        Observer.Expect('Evaluate Nej', 'ok|false');
        Observer.Expect('Evaluate Oui', 'rejected');
        Observer.Expect('Evaluate Non', 'rejected');
        Observer.Expect('Evaluate Y', 'rejected');
        Observer.Expect('Evaluate N', 'ok|false');
        Observer.Expect('Evaluate  Ja ', 'ok|true');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Errors_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1030);
        Observer.Expect('TryBool Yes', 'err');
        Observer.Expect('TryBool Yes|text', 'Værdien "Yes" kan ikke evalueres til typen Boolean.');
        Observer.Expect('TryBool Yes|code', 'Evaluate');
        Observer.Expect('TryBool Ja', 'ok');
        Observer.Expect('TryBool Oui', 'err');
        Observer.Expect('TryBool Oui|text', 'Værdien "Oui" kan ikke evalueres til typen Boolean.');
        Observer.Expect('TryBool Oui|code', 'Evaluate');
        Observer.Expect('Format true', 'Ja');
        Observer.Expect('Format true 0 9', 'true');
        Observer.Expect('Format true 1 9', 't');
        Observer.Expect('Format false', 'Nej');
        Observer.Expect('Format false 0 9', 'false');
        Observer.Expect('Format false 0 1', 'Nej');
        Observer.Expect('Format true 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Option_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1030);
        Observer.Expect('Option Open', 'ok|0');
        Observer.Expect('Option open', 'ok|0');
        Observer.Expect('Option Closed', 'ok|1');
        Observer.Expect('Option Open cap', 'rejected');
        Observer.Expect('Option Open BE', 'rejected');
        Observer.Expect('Option Gesloten BE', 'rejected');
        Observer.Expect('Option Gesloten NL', 'rejected');
        Observer.Expect('Option gesloten nl', 'rejected');
        Observer.Expect('Option Offen', 'rejected');
        Observer.Expect('Option offen', 'rejected');
        Observer.Expect('Option Geschlossen', 'rejected');
        Observer.Expect('Option Ouvert', 'rejected');
        Observer.Expect('Option Ferme', 'rejected');
        Observer.Expect('Option Aaben', 'ok|0');
        Observer.Expect('Option Lukket', 'ok|1');
        Observer.Expect('Option 1', 'ok|1');
        Observer.Expect('Format Closed', 'Lukket');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Enum_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1030);
        Observer.Expect('Enum Open', 'ok|0');
        Observer.Expect('Enum open', 'ok|0');
        Observer.Expect('Enum Closed', 'ok|1');
        Observer.Expect('Enum Open cap', 'rejected');
        Observer.Expect('Enum Open BE', 'rejected');
        Observer.Expect('Enum Gesloten BE', 'rejected');
        Observer.Expect('Enum Gesloten NL', 'rejected');
        Observer.Expect('Enum Offen', 'rejected');
        Observer.Expect('Enum Geschlossen', 'rejected');
        Observer.Expect('Enum Ouvert', 'rejected');
        Observer.Expect('Enum Ferme', 'rejected');
        Observer.Expect('Enum Aaben', 'ok|0');
        Observer.Expect('Enum Lukket', 'ok|1');
        Observer.Expect('Enum 1', 'ok|1');
        Observer.Expect('Format Closed', 'Lukket');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Date_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1030);
        Observer.Expect('Date 31.12.2026', 'rejected');
        Observer.Expect('Date 31/12/2026', 'rejected');
        Observer.Expect('Date 12/31/2026', 'ok|2026-12-31');
        Observer.Expect('Date 31-12-2026', 'rejected');
        Observer.Expect('Date 31-12-26', 'rejected');
        Observer.Expect('Date 2026-12-31', 'ok|2026-12-31');
        Observer.Expect('Date 311226', 'rejected');
        Observer.Expect('Date 31 december 2026', 'ok|2026-12-31');
        Observer.Expect('Date 31 Dezember 2026', 'rejected');
        Observer.Expect('Date 31. Dezember 2026', 'rejected');
        Observer.Expect('Date Dec 31 2026', 'rejected');
        Observer.Expect('Format date', '12/31/26');
        Observer.Expect('Format date 0 9', '2026-12-31');
        Observer.Expect('Format date 0 4', 'december 31, 2026');
        Observer.Expect('Format date 0 0', '12/31/26');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Words_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1033);
        Observer.Expect('Evaluate Yes', 'ok|true');
        Observer.Expect('Evaluate yes', 'ok|true');
        Observer.Expect('Evaluate No', 'ok|false');
        Observer.Expect('Evaluate true', 'ok|true');
        Observer.Expect('Evaluate False', 'ok|false');
        Observer.Expect('Evaluate 1', 'ok|true');
        Observer.Expect('Evaluate 0', 'ok|false');
        Observer.Expect('Evaluate Ja', 'rejected');
        Observer.Expect('Evaluate ja', 'rejected');
        Observer.Expect('Evaluate JA', 'rejected');
        Observer.Expect('Evaluate Nee', 'rejected');
        Observer.Expect('Evaluate Nein', 'rejected');
        Observer.Expect('Evaluate Nej', 'rejected');
        Observer.Expect('Evaluate Oui', 'rejected');
        Observer.Expect('Evaluate Non', 'rejected');
        Observer.Expect('Evaluate Y', 'ok|true');
        Observer.Expect('Evaluate N', 'ok|false');
        Observer.Expect('Evaluate  Ja ', 'rejected');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Errors_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1033);
        Observer.Expect('TryBool Yes', 'ok');
        Observer.Expect('TryBool Ja', 'err');
        Observer.Expect('TryBool Ja|text', 'The value "Ja" can''t be evaluated into type Boolean.');
        Observer.Expect('TryBool Ja|code', 'Evaluate');
        Observer.Expect('TryBool Oui', 'err');
        Observer.Expect('TryBool Oui|text', 'The value "Oui" can''t be evaluated into type Boolean.');
        Observer.Expect('TryBool Oui|code', 'Evaluate');
        Observer.Expect('Format true', 'Yes');
        Observer.Expect('Format true 0 9', 'true');
        Observer.Expect('Format true 1 9', 't');
        Observer.Expect('Format false', 'No');
        Observer.Expect('Format false 0 9', 'false');
        Observer.Expect('Format false 0 1', 'No');
        Observer.Expect('Format true 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Option_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1033);
        Observer.Expect('Option Open', 'ok|0');
        Observer.Expect('Option open', 'ok|0');
        Observer.Expect('Option Closed', 'ok|1');
        Observer.Expect('Option Open cap', 'ok|0');
        Observer.Expect('Option Open BE', 'rejected');
        Observer.Expect('Option Gesloten BE', 'rejected');
        Observer.Expect('Option Gesloten NL', 'rejected');
        Observer.Expect('Option gesloten nl', 'rejected');
        Observer.Expect('Option Offen', 'rejected');
        Observer.Expect('Option offen', 'rejected');
        Observer.Expect('Option Geschlossen', 'rejected');
        Observer.Expect('Option Ouvert', 'rejected');
        Observer.Expect('Option Ferme', 'rejected');
        Observer.Expect('Option Aaben', 'rejected');
        Observer.Expect('Option Lukket', 'rejected');
        Observer.Expect('Option 1', 'ok|1');
        Observer.Expect('Format Closed', 'Closed cap');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Enum_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1033);
        Observer.Expect('Enum Open', 'ok|0');
        Observer.Expect('Enum open', 'ok|0');
        Observer.Expect('Enum Closed', 'ok|1');
        Observer.Expect('Enum Open cap', 'ok|0');
        Observer.Expect('Enum Open BE', 'rejected');
        Observer.Expect('Enum Gesloten BE', 'rejected');
        Observer.Expect('Enum Gesloten NL', 'rejected');
        Observer.Expect('Enum Offen', 'rejected');
        Observer.Expect('Enum Geschlossen', 'rejected');
        Observer.Expect('Enum Ouvert', 'rejected');
        Observer.Expect('Enum Ferme', 'rejected');
        Observer.Expect('Enum Aaben', 'rejected');
        Observer.Expect('Enum Lukket', 'rejected');
        Observer.Expect('Enum 1', 'ok|1');
        Observer.Expect('Format Closed', 'Closed cap');
        Observer.Expect('Format Closed 0 9', '1');
        Observer.Expect('Format Closed 0 2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EL_Date_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1033);
        Observer.Expect('Date 31.12.2026', 'rejected');
        Observer.Expect('Date 31/12/2026', 'rejected');
        Observer.Expect('Date 12/31/2026', 'ok|2026-12-31');
        Observer.Expect('Date 31-12-2026', 'rejected');
        Observer.Expect('Date 31-12-26', 'rejected');
        Observer.Expect('Date 2026-12-31', 'ok|2026-12-31');
        Observer.Expect('Date 311226', 'rejected');
        Observer.Expect('Date 31 december 2026', 'ok|2026-12-31');
        Observer.Expect('Date 31 Dezember 2026', 'rejected');
        Observer.Expect('Date 31. Dezember 2026', 'rejected');
        Observer.Expect('Date Dec 31 2026', 'rejected');
        Observer.Expect('Format date', '12/31/26');
        Observer.Expect('Format date 0 9', '2026-12-31');
        Observer.Expect('Format date 0 4', 'December 31, 2026');
        Observer.Expect('Format date 0 0', '12/31/26');
        Observer.Verify();
    end;

    // Waldo run 2 (al-runner issue 6924): enums whose first member is blank. Enum 1 (97270): value(0; " ") without a caption. Enum 2 (97271):
    // the same member with Caption ' ' (ENU, ESP, NLB). Enum 3 (97272): value(0; "") with an empty name. For GlobalLanguage 1034, 2067 and 1033: the text
    // Format gives for the blank member (and with format 9 and 2), and what Evaluate does with that text, an empty text, blanks, the
    // member names, the captions and the ordinal. Start value is Second, so a value that is kept shows.

    local procedure WA_Enum1(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        E: Enum "LT WA Blank Enum";
        Blank: Enum "LT WA Blank Enum";
        WordList: List of [Text];
        Word: Text;
        Ok: Boolean;
    begin
        GlobalLanguage(Lang);
        Blank := Blank::" ";
        Observer.Observe('Format blank', '[' + Format(Blank) + ']');
        Observer.Observe('Format blank 0 9', '[' + Format(Blank, 0, 9) + ']');
        Observer.Observe('Format blank 0 2', '[' + Format(Blank, 0, 2) + ']');
        WordList.Add(Format(Blank));
        WordList.AddRange('', ' ', '  ', 'First', 'Primero', 'Eerste BE', 'first cap', 'First cap', '0');
        foreach Word in WordList do begin
            E := E::Second;
            ClearLastError();
            Ok := Evaluate(E, Word);
            if Ok then
                Observer.Observe('Evaluate [' + Word + ']', 'ok|' + Format(E, 0, 2) + '|[' + Format(E) + ']')
            else begin
                Observer.Observe('Evaluate [' + Word + ']', 'rejected|' + Format(E, 0, 2));
                Observer.ObserveError('Evaluate [' + Word + ']');
            end;
        end;
        E := E::Second;
        Ok := Evaluate(E, Format(Blank), 9);
        Observer.Observe('Evaluate format 9 of blank', Format(Ok) + '|' + Format(E, 0, 2));
        GlobalLanguage(1033);
    end;

    local procedure WA_Enum2(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        E: Enum "LT WA Blank Cap Enum";
        Blank: Enum "LT WA Blank Cap Enum";
        WordList: List of [Text];
        Word: Text;
        Ok: Boolean;
    begin
        GlobalLanguage(Lang);
        Blank := Blank::" ";
        Observer.Observe('Format blank', '[' + Format(Blank) + ']');
        Observer.Observe('Format blank 0 9', '[' + Format(Blank, 0, 9) + ']');
        Observer.Observe('Format blank 0 2', '[' + Format(Blank, 0, 2) + ']');
        WordList.Add(Format(Blank));
        WordList.AddRange('', ' ', '  ', 'First', 'Primero', 'Eerste BE', 'first cap', 'First cap', '0');
        foreach Word in WordList do begin
            E := E::Second;
            ClearLastError();
            Ok := Evaluate(E, Word);
            if Ok then
                Observer.Observe('Evaluate [' + Word + ']', 'ok|' + Format(E, 0, 2) + '|[' + Format(E) + ']')
            else begin
                Observer.Observe('Evaluate [' + Word + ']', 'rejected|' + Format(E, 0, 2));
                Observer.ObserveError('Evaluate [' + Word + ']');
            end;
        end;
        E := E::Second;
        Ok := Evaluate(E, Format(Blank), 9);
        Observer.Observe('Evaluate format 9 of blank', Format(Ok) + '|' + Format(E, 0, 2));
        GlobalLanguage(1033);
    end;

    local procedure WA_Enum3(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        E: Enum "LT WA Empty Name Enum";
        Blank: Enum "LT WA Empty Name Enum";
        WordList: List of [Text];
        Word: Text;
        Ok: Boolean;
    begin
        GlobalLanguage(Lang);
        Blank := Enum::"LT WA Empty Name Enum".FromInteger(0);
        Observer.Observe('Format blank', '[' + Format(Blank) + ']');
        Observer.Observe('Format blank 0 9', '[' + Format(Blank, 0, 9) + ']');
        Observer.Observe('Format blank 0 2', '[' + Format(Blank, 0, 2) + ']');
        WordList.Add(Format(Blank));
        WordList.AddRange('', ' ', '  ', 'First', 'Primero', 'Eerste BE', 'first cap', 'First cap', '0');
        foreach Word in WordList do begin
            E := E::Second;
            ClearLastError();
            Ok := Evaluate(E, Word);
            if Ok then
                Observer.Observe('Evaluate [' + Word + ']', 'ok|' + Format(E, 0, 2) + '|[' + Format(E) + ']')
            else begin
                Observer.Observe('Evaluate [' + Word + ']', 'rejected|' + Format(E, 0, 2));
                Observer.ObserveError('Evaluate [' + Word + ']');
            end;
        end;
        E := E::Second;
        Ok := Evaluate(E, Format(Blank), 9);
        Observer.Observe('Evaluate format 9 of blank', Format(Ok) + '|' + Format(E, 0, 2));
        GlobalLanguage(1033);
    end;

    [Test]
    procedure WA_BlankEnum1_ES_1034()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum1(Observer, 1034);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[Primero]');
        Observer.Expect('Evaluate [Primero]', 'ok|1|[Primero]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [first cap]', 'rejected|2');
        Observer.Expect('Evaluate [first cap]|text', '');
        Observer.Expect('Evaluate [first cap]|code', '');
        Observer.Expect('Evaluate [First cap]', 'rejected|2');
        Observer.Expect('Evaluate [First cap]|text', '');
        Observer.Expect('Evaluate [First cap]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Sí|0');
        Observer.Verify();
    end;

    [Test]
    procedure WA_BlankEnum1_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum1(Observer, 2067);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[Eerste BE]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [Eerste BE]', 'ok|1|[Eerste BE]');
        Observer.Expect('Evaluate [first cap]', 'rejected|2');
        Observer.Expect('Evaluate [first cap]|text', '');
        Observer.Expect('Evaluate [first cap]|code', '');
        Observer.Expect('Evaluate [First cap]', 'rejected|2');
        Observer.Expect('Evaluate [First cap]|text', '');
        Observer.Expect('Evaluate [First cap]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Ja|0');
        Observer.Verify();
    end;

    [Test]
    procedure WA_BlankEnum1_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum1(Observer, 1033);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [first cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure WA_BlankEnum2_ES_1034()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum2(Observer, 1034);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[Primero]');
        Observer.Expect('Evaluate [Primero]', 'ok|1|[Primero]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [first cap]', 'rejected|2');
        Observer.Expect('Evaluate [first cap]|text', '');
        Observer.Expect('Evaluate [first cap]|code', '');
        Observer.Expect('Evaluate [First cap]', 'rejected|2');
        Observer.Expect('Evaluate [First cap]|text', '');
        Observer.Expect('Evaluate [First cap]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Sí|0');
        Observer.Verify();
    end;

    [Test]
    procedure WA_BlankEnum2_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum2(Observer, 2067);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[Eerste BE]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [Eerste BE]', 'ok|1|[Eerste BE]');
        Observer.Expect('Evaluate [first cap]', 'rejected|2');
        Observer.Expect('Evaluate [first cap]|text', '');
        Observer.Expect('Evaluate [first cap]|code', '');
        Observer.Expect('Evaluate [First cap]', 'rejected|2');
        Observer.Expect('Evaluate [First cap]|text', '');
        Observer.Expect('Evaluate [First cap]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Ja|0');
        Observer.Verify();
    end;

    [Test]
    procedure WA_BlankEnum2_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum2(Observer, 1033);
        Observer.Expect('Format blank', '[ ]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate []', 'ok|0|[ ]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[ ]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [first cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [0]', 'ok|0|[ ]');
        Observer.Expect('Evaluate format 9 of blank', 'Yes|0');
        Observer.Verify();
    end;

    [Test]
    procedure WA_BlankEnum3_ES_1034()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum3(Observer, 1034);
        Observer.Expect('Format blank', '[0]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate []', 'ok|0|[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [First]', 'ok|1|[Primero]');
        Observer.Expect('Evaluate [Primero]', 'ok|1|[Primero]');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [first cap]', 'rejected|2');
        Observer.Expect('Evaluate [first cap]|text', '');
        Observer.Expect('Evaluate [first cap]|code', '');
        Observer.Expect('Evaluate [First cap]', 'rejected|2');
        Observer.Expect('Evaluate [First cap]|text', '');
        Observer.Expect('Evaluate [First cap]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate format 9 of blank', 'Sí|0');
        Observer.Verify();
    end;

    [Test]
    procedure WA_BlankEnum3_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum3(Observer, 2067);
        Observer.Expect('Format blank', '[0]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate []', 'ok|0|[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [First]', 'ok|1|[Eerste BE]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [Eerste BE]', 'ok|1|[Eerste BE]');
        Observer.Expect('Evaluate [first cap]', 'rejected|2');
        Observer.Expect('Evaluate [first cap]|text', '');
        Observer.Expect('Evaluate [first cap]|code', '');
        Observer.Expect('Evaluate [First cap]', 'rejected|2');
        Observer.Expect('Evaluate [First cap]|text', '');
        Observer.Expect('Evaluate [First cap]|code', '');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate format 9 of blank', 'Ja|0');
        Observer.Verify();
    end;

    [Test]
    procedure WA_BlankEnum3_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WA_Enum3(Observer, 1033);
        Observer.Expect('Format blank', '[0]');
        Observer.Expect('Format blank 0 9', '[0]');
        Observer.Expect('Format blank 0 2', '[0]');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate []', 'ok|0|[0]');
        Observer.Expect('Evaluate [ ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [  ]', 'ok|0|[0]');
        Observer.Expect('Evaluate [First]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [Primero]', 'rejected|2');
        Observer.Expect('Evaluate [Primero]|text', '');
        Observer.Expect('Evaluate [Primero]|code', '');
        Observer.Expect('Evaluate [Eerste BE]', 'rejected|2');
        Observer.Expect('Evaluate [Eerste BE]|text', '');
        Observer.Expect('Evaluate [Eerste BE]|code', '');
        Observer.Expect('Evaluate [first cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [First cap]', 'ok|1|[First cap]');
        Observer.Expect('Evaluate [0]', 'ok|0|[0]');
        Observer.Expect('Evaluate format 9 of blank', 'Yes|0');
        Observer.Verify();
    end;
}

// local objects of the WA_BlankEnum tests (al-runner issue 6924, waldo run 2).
enum 97270 "LT WA Blank Enum"
{
    Extensible = true;

    value(0; " ") { }
    value(1; First) { CaptionML = ENU = 'First cap', ESP = 'Primero', NLB = 'Eerste BE'; }
    value(2; Second) { CaptionML = ENU = 'Second cap', ESP = 'Segundo', NLB = 'Tweede BE'; }
}

enum 97271 "LT WA Blank Cap Enum"
{
    Extensible = true;

    value(0; " ") { CaptionML = ENU = ' ', ESP = ' ', NLB = ' '; }
    value(1; First) { CaptionML = ENU = 'First cap', ESP = 'Primero', NLB = 'Eerste BE'; }
    value(2; Second) { CaptionML = ENU = 'Second cap', ESP = 'Segundo', NLB = 'Tweede BE'; }
}

enum 97272 "LT WA Empty Name Enum"
{
    Extensible = true;

    value(0; "") { }
    value(1; First) { CaptionML = ENU = 'First cap', ESP = 'Primero', NLB = 'Eerste BE'; }
    value(2; Second) { CaptionML = ENU = 'Second cap', ESP = 'Segundo', NLB = 'Tweede BE'; }
}
