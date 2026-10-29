// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (69160); UrBlockOrderFixtures.al (main app: subscribers 50300, 50301, 90511, 90512, log 90513, publisher 90514),
//   install codeunits 50302 (_fixtures/ALTInstallProbe.al) and 90515 (types/TestBlankEnumInitInstaller.Codeunit.al).
// Probe (writer UR, al-runner NP Retail install order): install/lt-bf-install-probes/BfInstallTests.al saw install codeunit 81254 run BEFORE
//   60445, 60618 and 60894 (all four in this app, per-company part), which contradicts plain ascending id. 81254 is in the second block of
//   65536 ids. Candidate rules: (a) ascending id; (b) ascending id mod 65536; (c) higher block first, ascending inside a block;
//   (d) file / declaration order; descending id; name order. The ids, names and files are chosen so that each rule predicts another order
//   (see UrBlockOrderFixtures.al). Ids above 99999 (other blocks: 120000, 150100, 196000, 1000000, 6014438, 6059909) were probed in cross-app
//   fixture D but cannot be published: "Your program license does not allow you to publish 'LT UR XD S7'." (BC SaaS sandbox, id 120000).
// Measured (BC 29.0 SaaS sandbox; CI 27.5, 28.5, 29.0):
//   1. Install codeunit triggers and "Extension Triggers" install subscribers of one app run in ONE sequence in ascending codeunit id, across
//      the 65536 block boundary (50300, 50301, 50302 before 90511, 90512, 90515), in each company and in the per-database part. This refutes
//      "id mod 65536" and "higher block first". Rule (a) holds.
//   2. An ordinary integration event of this app runs its subscribers in ascending codeunit id across the block boundary too (both raises).
//   3. Why BfInstallTests.al saw 60445, 60618 and 60894 after 81254: those installers write with a plain Insert() (return value not used,
//      no AutoIncrement). Such an insert is buffered: the row gets its SystemRowVersion only when the buffer is written. Install codeunit
//      50302 inserts a row plainly and then another row with `if Insert() then;`: the plain row has the higher SystemRowVersion. In the
//      sliced app on the SaaS sandbox its SystemRowVersion was higher than the log rows of every later routine of that company (90511, 90512,
//      90515); not asserted, because that depends on the other install routines of the app (a Commit in between would write the buffer earlier).
//      So SystemRowVersion of a plainly inserted row does not show when the install routine ran. In a test session the same: a plain Insert() gets a higher SystemRowVersion than a later insert
//      into another table (written with `if Insert() then;`), and a lower one than a later checked Insert into the same table.
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
        Observer.Expect('rows', '18');
        Observer.Expect('sessions', '1');
        Observer.Expect('order', 'company (session company): S50300 S50301 I50302 S90511 S90512 I90515 | company (other company): S50300 S50301 I50302 S90511 S90512 I90515 | database (blank): S50300 S50301 I50302 S90511 S90512 I90515');
        Observer.Verify();
    end;

    [Test]
    procedure MainApp_OrdinaryEvent_SubscriberOrderAcrossIdBlocks()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "LT UR Publisher";
    begin
        Observer.Observe('first raise', Publisher.Raise());
        Observer.Observe('second raise', Publisher.Raise());
        Observer.Expect('first raise', '50300;50301;90511;90512;');
        Observer.Expect('second raise', '50300;50301;90511;90512;');
        Observer.Verify();
    end;

    // Install codeunit 50302, per company: a plain Insert() of "LT UR Buffered Row", then a checked insert of "LT UR Plain Row" (AutoIncrement).
    // Which of the two rows has the higher SystemRowVersion, in the session company.
    [Test]
    procedure MainApp_InstallPlainInsert_RowVersionAgainstLaterInsert()
    var
        Observer: Codeunit "Probe Observer";
        Buffered: Record "LT UR Buffered Row";
        After: Record "LT UR Plain Row";
    begin
        Observer.Observe('buffered row', Format(Buffered.Get('I50302')));
        After.SetRange(Note, 'I50302 after');
        Observer.Observe('later row', Format(After.FindFirst()));
        Observer.Observe('plain insert > later insert', Format(Buffered.SystemRowVersion > After.SystemRowVersion));
        Observer.Expect('buffered row', 'Yes');
        Observer.Expect('later row', 'Yes');
        Observer.Expect('plain insert > later insert', 'Yes');
        Observer.Verify();
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
        Plain.SetRange(Note, 'P');
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
        Plain.FindLast();
        PlainVersion := Plain.SystemRowVersion;
        Buffered.Get('T1');
        Checked.Get('T2');
        Observer.Observe('T1 > P', Format(Buffered.SystemRowVersion > PlainVersion));
        Observer.Observe('T2 > P', Format(Checked.SystemRowVersion > PlainVersion));
        Observer.Observe('T1 > T2', Format(Buffered.SystemRowVersion > Checked.SystemRowVersion));
        Observer.Expect('T1 > P', 'Yes');
        Observer.Expect('T2 > P', 'Yes');
        Observer.Expect('T1 > T2', 'No');
        Observer.Verify();
    end;
}
