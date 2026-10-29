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
}
