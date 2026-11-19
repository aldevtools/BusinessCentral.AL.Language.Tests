namespace ALLanguage.IsolationProbe;

// Asserts every reading of the RecordRef cells after a failed test (SqRecordRefFail.al; facts in its header). Runs after
// the cell codeunits 76241-76255 (a higher id). EXPECTED-NOTE
codeunit 76269 "LT SQ Ref Reader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT SQ Log";
        Helper: Codeunit "LT SQ Helper";

    // Runs first: what a later test codeunit sees of every cell's sequence (state, then the number Next gives).
    [Test]
    procedure A_ReadsInLaterCodeunit()
    begin
        Helper.Read('R14O later', Log.Seq('R14O'));
        Helper.Read('R14V later', Log.Seq('R14V'));
        Helper.Read('R14P later', Log.Seq('R14P'));
        Helper.Read('R14W later', Log.Seq('R14W'));
        Helper.Read('R14N later', Log.Seq('R14N'));
        Helper.Read('R14E later', Log.Seq('R14E'));
        Helper.Read('R14M later', Log.Seq('R14M'));
        Helper.Read('R14R later', Log.Seq('R14R'));
        Helper.Read('R2O later', Log.Seq('R2O'));
        Helper.Read('R2V later', Log.Seq('R2V'));
        Helper.Read('R2P later', Log.Seq('R2P'));
        Helper.Read('R2W later', Log.Seq('R2W'));
        Helper.Read('R2N later', Log.Seq('R2N'));
        Helper.Read('R2M later', Log.Seq('R2M'));
        Helper.Read('R2R later', Log.Seq('R2R'));
    end;

    [Test]
    procedure R14O_Reading()
    begin
        Check('R14O', 'R14O first no|R14O access|R14O lines|R14O after state|R14O after no|R14O later state|R14O later next',
            '');
    end;

    [Test]
    procedure R14V_Reading()
    begin
        Check('R14V', 'R14V first no|R14V access|R14V lines|R14V after state|R14V after no|R14V later state|R14V later next',
            '');
    end;

    [Test]
    procedure R14P_Reading()
    begin
        Check('R14P', 'R14P first no|R14P access|R14P lines|R14P after state|R14P after no|R14P later state|R14P later next',
            '');
    end;

    [Test]
    procedure R14W_Reading()
    begin
        Check('R14W', 'R14W first no|R14W access|R14W lines|R14W after state|R14W after no|R14W later state|R14W later next',
            '');
    end;

    [Test]
    procedure R14N_Reading()
    begin
        Check('R14N', 'R14N first no|R14N access|R14N lines|R14N after state|R14N after no|R14N later state|R14N later next',
            '');
    end;

    [Test]
    procedure R14E_Reading()
    begin
        Check('R14E', 'R14E first no|R14E access|R14E lines|R14E after state|R14E after no|R14E later state|R14E later next',
            '');
    end;

    [Test]
    procedure R14M_Reading()
    begin
        Check('R14M', 'R14M first no|R14M access|R14M lines|R14M after state|R14M after no|R14M later state|R14M later next',
            '');
    end;

    [Test]
    procedure R14R_Reading()
    begin
        Check('R14R', 'R14R first no|R14R access|R14R lines|R14R after state|R14R after no|R14R later state|R14R later next',
            '');
    end;

    [Test]
    procedure R2O_Reading()
    begin
        Check('R2O', 'R2O first next|R2O access|R2O lines|R2O after state|R2O after next|R2O later state|R2O later next',
            '');
    end;

    [Test]
    procedure R2V_Reading()
    begin
        Check('R2V', 'R2V first next|R2V access|R2V lines|R2V after state|R2V after next|R2V later state|R2V later next',
            '');
    end;

    [Test]
    procedure R2P_Reading()
    begin
        Check('R2P', 'R2P first next|R2P access|R2P lines|R2P after state|R2P after next|R2P later state|R2P later next',
            '');
    end;

    [Test]
    procedure R2W_Reading()
    begin
        Check('R2W', 'R2W first next|R2W access|R2W lines|R2W after state|R2W after next|R2W later state|R2W later next',
            '');
    end;

    [Test]
    procedure R2N_Reading()
    begin
        Check('R2N', 'R2N first next|R2N access|R2N lines|R2N after state|R2N after next|R2N later state|R2N later next',
            '');
    end;

    [Test]
    procedure R2M_Reading()
    begin
        Check('R2M', 'R2M first next|R2M access|R2M lines|R2M after state|R2M after next|R2M later state|R2M later next',
            '');
    end;

    [Test]
    procedure R2R_Reading()
    begin
        Check('R2R', 'R2R first next|R2R access|R2R lines|R2R after state|R2R after next|R2R later state|R2R later next',
            '');
    end;

    // "key=value | key=value" of the |-separated keys.
    local procedure Reading(Keys: Text): Text
    var
        EntryKey: Text;
        Result: Text;
    begin
        foreach EntryKey in Keys.Split('|') do begin
            if Result <> '' then
                Result += ' | ';
            Result += EntryKey + '=' + Log.Get(EntryKey);
        end;
        exit(Result);
    end;

    // A failure message carries what was observed instead of the expected reading.
    local procedure Check(Cell: Text; Keys: Text; Expected: Text)
    var
        Actual: Text;
    begin
        Actual := Reading(Keys);
        if Actual <> Expected then
            Error('OBSERVE %1: %2', Cell, Actual);
    end;
}
