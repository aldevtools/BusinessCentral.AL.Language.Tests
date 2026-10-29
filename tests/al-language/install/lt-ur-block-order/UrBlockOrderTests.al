// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); UrBlockOrderFixtures.al (main app: subscribers 50300, 50301, 90511, 90512, log 90513, publisher 90514),
//   install codeunits 50302 (_fixtures/ALTInstallProbe.al) and 90515 (types/TestBlankEnumInitInstaller.Codeunit.al).
// Probe (writer UR, al-runner NP Retail install order): install/lt-bf-install-probes/BfInstallTests.al saw install codeunit 81254 run BEFORE
//   60445, 60618 and 60894 (all four in this app, per-company part), which contradicts plain ascending id. 81254 is in the second block of
//   65536 ids. Candidate rules: (a) ascending id; (b) ascending id mod 65536; (c) higher block first, ascending inside a block;
//   (d) file / declaration order; descending id; name order. The ids, names and files are chosen so that each rule predicts another order
//   (see the two fixture files).
// BC versions: 27 - 29
codeunit 90510 "LT UR Block Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if Company = CompanyName() then
            exit('session company');
        exit('other company');
    end;

    // One line per part of the install run, in the order the parts ran: "<part> (<company>): <routines in run order>".
    local procedure Groups(Routines: List of [Text]; Parts: List of [Text]): Text
    var
        Result: Text;
        Current: Text;
        Index: Integer;
    begin
        for Index := 1 to Routines.Count() do begin
            if Parts.Get(Index) <> Current then begin
                Current := Parts.Get(Index);
                if Result <> '' then
                    Result += ' | ';
                Result += Current + ':';
            end;
            Result += ' ' + Routines.Get(Index);
        end;
        exit(Result);
    end;

    [Test]
    procedure MainApp_InstallRoutines_OrderAcrossIdBlocks()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UR Install Log";
        Routines: List of [Text];
        Parts: List of [Text];
        Sessions: List of [Integer];
    begin
        if Row.FindSet() then
            repeat
                Routines.Add(Row.Routine);
                Parts.Add(Row.Part + ' (' + Tag(Row.Company) + ')');
                if not Sessions.Contains(Row."Session Id") then
                    Sessions.Add(Row."Session Id");
            until Row.Next() = 0;
        Observer.Observe('rows', Format(Routines.Count()));
        Observer.Observe('sessions', Format(Sessions.Count()));
        Observer.Observe('order', Groups(Routines, Parts));
        Observer.Finish();
    end;

    [Test]
    procedure MainApp_OrdinaryEvent_SubscriberOrderAcrossIdBlocks()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "LT UR Publisher";
    begin
        Observer.Observe('first raise', Publisher.Raise());
        Observer.Observe('second raise', Publisher.Raise());
        Observer.Finish();
    end;

    // The row install codeunit 50302 wrote with a plain Insert() in the session company, against the log rows (written with
    // `if Insert() then;` into an AutoIncrement table) of the same company: which log rows have a lower SystemRowVersion.
    [Test]
    procedure MainApp_InstallPlainInsert_RowVersionAgainstLog()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UR Install Log";
        Buffered: Record "LT UR Buffered Row";
        Before: Text;
        After: Text;
    begin
        Observer.Observe('buffered row', Format(Buffered.Get('I50302')));
        Row.SetRange(Part, 'company');
        Row.SetRange(Company, CompanyName());
        if Row.FindSet() then
            repeat
                if Row.SystemRowVersion < Buffered.SystemRowVersion then
                    Before += Row.Routine + ' '
                else
                    After += Row.Routine + ' ';
            until Row.Next() = 0;
        Observer.Observe('log rows before it', Before);
        Observer.Observe('log rows after it', After);
        Observer.Finish();
    end;

    // The same question outside install code: a plain Insert(), then an insert into an AutoIncrement table, then an Insert whose
    // return value is used; SystemRowVersion order of the three rows.
    [Test]
    procedure TestSession_PlainInsert_RowVersionAgainstLaterInserts()
    var
        Observer: Codeunit "Probe Observer";
        Buffered: Record "LT UR Buffered Row";
        Checked: Record "LT UR Buffered Row";
        Plain: Record "LT UR Plain Row";
        PlainVersion: BigInteger;
    begin
        Buffered.SetFilter(Code, 'T*');
        Buffered.DeleteAll();
        Plain.DeleteAll();
        Buffered.Init();
        Buffered.Code := 'T1';
        Buffered.Insert();
        Plain.Init();
        Plain.Note := 'P';
        if Plain.Insert() then;
        Checked.Init();
        Checked.Code := 'T2';
        if Checked.Insert() then;
        Observer.Observe('T1 after insert', Format(Buffered.SystemRowVersion = 0));
        Plain.FindFirst();
        PlainVersion := Plain.SystemRowVersion;
        Buffered.Get('T1');
        Checked.Get('T2');
        Observer.Observe('T1 > P', Format(Buffered.SystemRowVersion > PlainVersion));
        Observer.Observe('T2 > P', Format(Checked.SystemRowVersion > PlainVersion));
        Observer.Observe('T1 > T2', Format(Buffered.SystemRowVersion > Checked.SystemRowVersion));
        Observer.Finish();
    end;
}
