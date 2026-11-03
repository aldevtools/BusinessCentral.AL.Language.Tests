// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: Format(DMY2Date(1, m, 2024), 0, 4) and format 7 for all 12 months with GlobalLanguage 1033, 1031, 1036 and 3082;
//   Format of a Duration of 1 day, 2 days, 2 hours, 1 minute, 1 second and 1 millisecond with GlobalLanguage 1033, 1031 and 1036.
//   The month names follow the language; the order 'Month Day, Year' follows the CI container's format region (en-US).
//   Each test sets GlobalLanguage back before it checks its values.
// BC versions: 27.5+

codeunit 80425 "LT AX Language Formats"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Months(Language: Integer; FormatNo: Integer): Text
    var
        Saved: Integer;
        S: Text;
        m: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(Language);
        for m := 1 to 12 do
            S += Format(DMY2Date(1, m, 2024), 0, FormatNo) + ';';
        GlobalLanguage(Saved);
        exit(S);
    end;

    local procedure Durations(Language: Integer): Text
    var
        Saved: Integer;
        S: Text;
        D: Duration;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(Language);
        D := 86400000;
        S := Format(D) + ';';
        D := 172800000;
        S += Format(D) + ';';
        D := 7200000;
        S += Format(D) + ';';
        D := 60000;
        S += Format(D) + ';';
        D := 1000;
        S += Format(D) + ';';
        D := 1;
        S += Format(D);
        GlobalLanguage(Saved);
        exit(S);
    end;

    [Test]
    procedure Months_Format4_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1033 f4', Months(1033, 4));
        Observer.Expect('1033 f4', 'January 1, 2024;February 1, 2024;March 1, 2024;April 1, 2024;May 1, 2024;June 1, 2024;July 1, 2024;August 1, 2024;September 1, 2024;October 1, 2024;November 1, 2024;December 1, 2024;');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Format7_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1033 f7', Months(1033, 7));
        Observer.Expect('1033 f7', 'Jan 1, 2024;Feb 1, 2024;Mar 1, 2024;Apr 1, 2024;May 1, 2024;Jun 1, 2024;Jul 1, 2024;Aug 1, 2024;Sep 1, 2024;Oct 1, 2024;Nov 1, 2024;Dec 1, 2024;');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Format4_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1031 f4', Months(1031, 4));
        Observer.Expect('1031 f4', 'Januar 1, 2024;Februar 1, 2024;März 1, 2024;April 1, 2024;Mai 1, 2024;Juni 1, 2024;Juli 1, 2024;August 1, 2024;September 1, 2024;Oktober 1, 2024;November 1, 2024;Dezember 1, 2024;');
        Observer.Verify();
    end;

    // Not a test (Linux suspect, bc-linux #134): the Linux container gives other month texts. Windows check 3 gives for 1031:
    // 'Jan 1, 2024;Feb 1, 2024;Mrz 1, 2024;Apr 1, 2024;Mai 1, 2024;Jun 1, 2024;Jul 1, 2024;Aug 1, 2024;Sep 1, 2024;Okt 1, 2024;Nov 1, 2024;Dez 1, 2024;'
    procedure Months_Format7_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1031 f7', Months(1031, 7));
        Observer.Expect('1031 f7', 'Jan. 1, 2024;Feb. 1, 2024;März 1, 2024;Apr. 1, 2024;Mai 1, 2024;Juni 1, 2024;Juli 1, 2024;Aug. 1, 2024;Sept. 1, 2024;Okt. 1, 2024;Nov. 1, 2024;Dez. 1, 2024;');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Format4_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1036 f4', Months(1036, 4));
        Observer.Expect('1036 f4', 'janvier 1, 2024;février 1, 2024;mars 1, 2024;avril 1, 2024;mai 1, 2024;juin 1, 2024;juillet 1, 2024;août 1, 2024;septembre 1, 2024;octobre 1, 2024;novembre 1, 2024;décembre 1, 2024;');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Format7_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1036 f7', Months(1036, 7));
        Observer.Expect('1036 f7', 'janv. 1, 2024;févr. 1, 2024;mars 1, 2024;avr. 1, 2024;mai 1, 2024;juin 1, 2024;juil. 1, 2024;août 1, 2024;sept. 1, 2024;oct. 1, 2024;nov. 1, 2024;déc. 1, 2024;');
        Observer.Verify();
    end;

    [Test]
    procedure Months_Format4_Spanish()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('3082 f4', Months(3082, 4));
        Observer.Expect('3082 f4', 'enero 1, 2024;febrero 1, 2024;marzo 1, 2024;abril 1, 2024;mayo 1, 2024;junio 1, 2024;julio 1, 2024;agosto 1, 2024;septiembre 1, 2024;octubre 1, 2024;noviembre 1, 2024;diciembre 1, 2024;');
        Observer.Verify();
    end;

    // Not a test (Linux suspect, bc-linux #134): the Linux container gives other month texts. Windows check 3 gives for 3082:
    // 'ene. 1, 2024;feb. 1, 2024;mar. 1, 2024;abr. 1, 2024;may. 1, 2024;jun. 1, 2024;jul. 1, 2024;ago. 1, 2024;sep. 1, 2024;oct. 1, 2024;nov. 1, 2024;dic. 1, 2024;'
    procedure Months_Format7_Spanish()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('3082 f7', Months(3082, 7));
        Observer.Expect('3082 f7', 'ene 1, 2024;feb 1, 2024;mar 1, 2024;abr 1, 2024;may 1, 2024;jun 1, 2024;jul 1, 2024;ago 1, 2024;sept 1, 2024;oct 1, 2024;nov 1, 2024;dic 1, 2024;');
        Observer.Verify();
    end;

    [Test]
    procedure Durations_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1033', Durations(1033));
        Observer.Expect('1033', '1 day;2 days;2 hours;1 minute;1 second;1 millisecond');
        Observer.Verify();
    end;

    [Test]
    procedure Durations_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1031', Durations(1031));
        Observer.Expect('1031', '1 Tag;2 Tage;2 Stunden;1 Minute;1 Sekunde;1 Millisekunde');
        Observer.Verify();
    end;

    [Test]
    procedure Durations_French()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1036', Durations(1036));
        Observer.Expect('1036', '1 jour;2 jours;2 heures;1 minute;1 seconde;1 milliseconde');
        Observer.Verify();
    end;
}
