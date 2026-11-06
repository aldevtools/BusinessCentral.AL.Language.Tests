// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 96280-96283 (LT EL Row, LT EL Status, LT EL Eval)
// Probe: from al-runner issue 6924 (waldo): under GlobalLanguage 2067 (nl-BE) Evaluate(BoolVar, 'Ja') succeeds on BC and Format(BoolVar, 0, 9) is 'true'.
//   For GlobalLanguage 2067, 1043, 1031, 1036, 1030 and 1033: which texts Evaluate accepts into a Boolean (Yes, yes, No, true, False, 1, 0, Ja, ja, JA,
//   Nee, Nein, Nej, Oui, Non, Y, N), the error text and code of a rejected one, Format(Bool) and Format(Bool, 0, 9); Evaluate into an Option field and
//   an Enum (name, caption, caption under the language, ordinal) and their Format; Evaluate of date texts and Format(Date) and Format(Date, 0, 9).
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
        Observer.Finish();
    end;

    [Test]
    procedure EL_Errors_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 2067);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Option_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 2067);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Enum_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 2067);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Date_NLB_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 2067);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Words_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Errors_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Option_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Enum_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Date_NLD_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Words_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Errors_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Option_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Enum_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Date_DEU_1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Words_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Errors_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Option_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Enum_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Date_FRA_1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Words_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Errors_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Option_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Enum_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Date_DAN_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Words_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunWords(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Errors_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunErrors(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Option_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunOption(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Enum_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunEnum(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure EL_Date_ENU_1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunDate(Observer, 1033);
        Observer.Finish();
    end;

}
