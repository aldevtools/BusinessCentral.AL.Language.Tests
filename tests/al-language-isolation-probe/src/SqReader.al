namespace ALLanguage.IsolationProbe;

// READER-HEADER-PLACEHOLDER
codeunit 76089 "LT SQ Reader"
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
        Helper.Read('C1 later', Log.Seq('C1'));
        Helper.Read('C2 later', Log.Seq('C2'));
        Helper.Read('C3 later', Log.Seq('C3'));
        Helper.Read('C4 later', Log.Seq('C4'));
        Helper.Read('C5 later', Log.Seq('C5'));
        Helper.Read('C6 later', Log.Seq('C6'));
        Helper.Read('C7 later', Log.Seq('C7'));
        Helper.Read('C8 later', Log.Seq('C8'));
        Helper.Read('C9 later', Log.Seq('C9'));
        Helper.Read('C10 later', Log.Seq('C10'));
        Helper.Read('C11 later', Log.Seq('C11'));
        Helper.Read('C12 later', Log.Seq('C12'));
        Helper.Read('C13 later', Log.Seq('C13'));
        Helper.Read('C14 later', Log.Seq('C14'));
        Helper.Read('C15 later', Log.Seq('C15'));
        Helper.Read('C16 later', Log.Seq('C16'));
        Helper.Read('D1 later', Log.Seq('D1'));
        Helper.Read('D2 later', Log.Seq('D2'));
        Helper.Read('D3 later', Log.Seq('D3'));
        Helper.Read('D4 later', Log.Seq('D4'));
        Helper.Read('D5 later', Log.Seq('D5'));
        Helper.Read('D6 later', Log.Seq('D6'));
        Helper.Read('D7 later', Log.Seq('D7'));
        Helper.Read('B1 later', Log.Seq('B1'));
        Helper.Read('B2 later', Log.Seq('B2'));
        Helper.Read('B3 later', Log.Seq('B3'));
        Helper.Read('B4 later', Log.Seq('B4'));
        Helper.Read('B5 later', Log.Seq('B5'));
        Helper.Read('B6 later', Log.Seq('B6'));
    end;

    [Test]
    procedure C1_Reading()
    begin
        Check('C1', 'C1 first next|C1 rows|C1 after state|C1 after next|C1 later state|C1 later next');
    end;

    [Test]
    procedure C2_Reading()
    begin
        Check('C2', 'C2 first next|C2 rows|C2 after state|C2 after next|C2 later state|C2 later next');
    end;

    [Test]
    procedure C3_Reading()
    begin
        Check('C3', 'C3 first next|C3 after state|C3 after next|C3 later state|C3 later next');
    end;

    [Test]
    procedure C4_Reading()
    begin
        Check('C4', 'C4 rows before|C4 inserted|C4 rows after|C4 later state|C4P rows before|C4P inserted');
    end;

    [Test]
    procedure C5_Reading()
    begin
        Check('C5', 'C5 first next|C5 handler ran|C5 write tx after handler|C5 rows|C5 after state|C5 after next|C5 later state|C5 later next');
    end;

    [Test]
    procedure C6_Reading()
    begin
        Check('C6', 'C6 first next|C6 write tx before run|C6 run|C6 run error|C6 rows|C6 after state|C6 after next|C6 later state|C6 later next');
    end;

    [Test]
    procedure C7_Reading()
    begin
        Check('C7', 'C7 first next|C7 write tx after event|C7 rows|C7 after state|C7 after next|C7 later state|C7 later next');
    end;

    [Test]
    procedure C8_Reading()
    begin
        Check('C8', 'C8 first next|C8 after state|C8 after next|C8 later state|C8 later next');
    end;

    [Test]
    procedure C9_Reading()
    begin
        Check('C9', 'C9 first next|C9 after state|C9 after next|C9 later state|C9 later next');
    end;

    [Test]
    procedure C10_Reading()
    begin
        Check('C10', 'C10 first next|C10 state before commit|C10 after state|C10 after next|C10 later state|C10 later next');
    end;

    [Test]
    procedure C11_Reading()
    begin
        Check('C11', 'C11 first next|C11 after state|C11 after next|C11 later state|C11 later next');
    end;

    [Test]
    procedure C12_Reading()
    begin
        Check('C12', 'C12 first next|C12 write tx after ignored commit|C12 rows|C12 after state|C12 after next|C12 later state|C12 later next');
    end;

    [Test]
    procedure C13_Reading()
    begin
        Check('C13', 'C13 first next|C13 after state|C13 after next|C13 later state|C13 later next');
    end;

    [Test]
    procedure C14_Reading()
    begin
        Check('C14', 'C14 first no|C14 rows|C14 after state|C14 after no|C14 later state|C14 later next');
    end;

    [Test]
    procedure C15_Reading()
    begin
        Check('C15', 'C15 first no|C15 after state|C15 after no|C15 later state|C15 later next');
    end;

    [Test]
    procedure C16_Reading()
    begin
        Check('C16', 'C16 first no|C16 after state|C16 after no|C16 later state|C16 later next');
    end;

    [Test]
    procedure D1_Reading()
    begin
        Check('D1', 'D1 write tx at start|D1 first next|D1 rows|D1 after state|D1 after next|D1 later state|D1 later next');
    end;

    [Test]
    procedure D2_Reading()
    begin
        Check('D2', 'D2 first next|D2 rows|D2 after state|D2 after next|D2 later state|D2 later next');
    end;

    [Test]
    procedure D3_Reading()
    begin
        Check('D3', 'D3 first next|D3 rows|D3 after state|D3 after next|D3 later state|D3 later next');
    end;

    [Test]
    procedure D4_Reading()
    begin
        Check('D4', 'D4 first next|D4 after state|D4 after next|D4 later state|D4 later next');
    end;

    [Test]
    procedure D5_Reading()
    begin
        Check('D5', 'D5 first next|D5 rows|D5 after state|D5 after next|D5 later state|D5 later next');
    end;

    [Test]
    procedure D6_Reading()
    begin
        Check('D6', 'D6 first next|D6 after state|D6 after next|D6 later state|D6 later next');
    end;

    [Test]
    procedure D7_Reading()
    begin
        Check('D7', 'D7 first next|D7 rows|D7 after state|D7 after next|D7 later state|D7 later next');
    end;

    [Test]
    procedure B1_Reading()
    begin
        Check('B1', 'B1 onrun state|B1 start state|B1 changed state|B1 after state|B1 after next|B1 later state|B1 later next');
    end;

    [Test]
    procedure B2_Reading()
    begin
        Check('B2', 'B2 onrun state|B2 start state|B2 changed state|B2 after state|B2 after next|B2 later state|B2 later next');
    end;

    [Test]
    procedure B3_Reading()
    begin
        Check('B3', 'B3 onrun state|B3 start state|B3 changed state|B3 after state|B3 after next|B3 later state|B3 later next');
    end;

    [Test]
    procedure B4_Reading()
    begin
        Check('B4', 'B4 onrun state|B4 start state|B4 changed state|B4 after state|B4 after next|B4 later state|B4 later next');
    end;

    [Test]
    procedure B5_Reading()
    begin
        Check('B5', 'B5 onrun state|B5 start state|B5 taken|B5 changed state|B5 after state|B5 after next|B5 later state|B5 later next');
    end;

    [Test]
    procedure B6_Reading()
    begin
        Check('B6', 'B6 onrun state|B6 start state|B6 taken|B6 changed state|B6 after state|B6 after next|B6 later state|B6 later next');
    end;

    [Test]
    procedure P5a_Reading()
    begin
        Check('P5a', 'P5a first hits|P5a second hits|P5a third hits|P5a third error');
    end;

    [Test]
    procedure P5b_Reading()
    begin
        Check('P5b', 'P5b first hits|P5b second hits');
    end;

    [Test]
    procedure P5c_Reading()
    begin
        Check('P5c', 'P5c first hits|P5c unbind|P5c hits after unbind');
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

    local procedure Check(Cell: Text; Keys: Text)
    begin
        Error('OBSERVE %1: %2', Cell, Reading(Keys));
    end;
}
