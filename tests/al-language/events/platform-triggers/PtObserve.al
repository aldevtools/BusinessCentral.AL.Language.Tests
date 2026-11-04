// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); PtFixtures.al (69880, 69881) and PtObjects.al (69882-69885, 70480)
// BC versions: 27.0 to 29.0
// Every question is asked with the log mode 0 (subscribers silent), 1 (log), 2 (log and change the var parameters) and 3 (the Make*Filter subscribers repair the filter text).

codeunit 69886 "LT W Pt Observe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Short(Value: Text): Text
    begin
        exit(CopyStr(Value, 1, 330));
    end;

    local procedure Act(Which: Text)
    var
        Log: Codeunit "LT W Pt Log";
        Mode: Integer;
        Ok: Boolean;
        Err: Text;
        FirstErr: Text;
        Res: Text;
        LogText: Text;
    begin
        for Mode := 0 to 3 do begin
            Log.SetMode(Mode);
            Log.Reset();
            Log.SetWhich(Which);
            Ok := Codeunit.Run(Codeunit::"LT W Pt Runner");
            Err := '';
            if not Ok then
                Err := GetLastErrorText();
            ClearLastError();
            Log.SetMode(0);
            Res := Log.Result();
            // the host name and the build numbers differ from run to run
            if Which in ['appver', 'appbuild', 'buildfile', 'platfile', 'geturl'] then
                Res := Format(Res <> '');
            LogText := Log.Dump();
            // the second event of a failed DateTime filter carries a text made from the work date
            if (Which = 'baddatetime') and (Mode = 2) then
                LogText := 'count=' + Format(Log.Count());
            if Mode = 0 then begin
                FirstErr := Err;
                Observer.Observe(Which + '|err', Err);
            end else
                Observer.Observe(Which + '|m' + Format(Mode) + '|err-same', Format(Err = FirstErr));
            Observer.Observe(Which + '|m' + Format(Mode), 'ok=' + Format(Ok) + ' res=' + Res + ' log=' + Short(LogText));
        end;
    end;

    [Test]
    procedure Version()
    begin
        Act('appver');
        Act('appbuild');
        Act('buildfile');
        Act('platfile');
        Observer.Expect('appver|err', '');
        Observer.Expect('appver|m0', 'ok=Yes res=Yes log=[]');
        Observer.Expect('appver|m1|err-same', 'Yes');
        Observer.Expect('appver|m1', 'ok=Yes res=Yes log=[]');
        Observer.Expect('appver|m2|err-same', 'Yes');
        Observer.Expect('appver|m2', 'ok=Yes res=Yes log=[]');
        Observer.Expect('appver|m3|err-same', 'Yes');
        Observer.Expect('appver|m3', 'ok=Yes res=Yes log=[]');
        Observer.Expect('appbuild|err', '');
        Observer.Expect('appbuild|m0', 'ok=Yes res=Yes log=[]');
        Observer.Expect('appbuild|m1|err-same', 'Yes');
        Observer.Expect('appbuild|m1', 'ok=Yes res=Yes log=[]');
        Observer.Expect('appbuild|m2|err-same', 'Yes');
        Observer.Expect('appbuild|m2', 'ok=Yes res=Yes log=[]');
        Observer.Expect('appbuild|m3|err-same', 'Yes');
        Observer.Expect('appbuild|m3', 'ok=Yes res=Yes log=[]');
        Observer.Expect('buildfile|err', '');
        Observer.Expect('buildfile|m0', 'ok=Yes res=Yes log=[]');
        Observer.Expect('buildfile|m1|err-same', 'Yes');
        Observer.Expect('buildfile|m1', 'ok=Yes res=Yes log=[]');
        Observer.Expect('buildfile|m2|err-same', 'Yes');
        Observer.Expect('buildfile|m2', 'ok=Yes res=Yes log=[]');
        Observer.Expect('buildfile|m3|err-same', 'Yes');
        Observer.Expect('buildfile|m3', 'ok=Yes res=Yes log=[]');
        Observer.Expect('platfile|err', '');
        Observer.Expect('platfile|m0', 'ok=Yes res=Yes log=[]');
        Observer.Expect('platfile|m1|err-same', 'Yes');
        Observer.Expect('platfile|m1', 'ok=Yes res=Yes log=[]');
        Observer.Expect('platfile|m2|err-same', 'Yes');
        Observer.Expect('platfile|m2', 'ok=Yes res=Yes log=[]');
        Observer.Expect('platfile|m3|err-same', 'Yes');
        Observer.Expect('platfile|m3', 'ok=Yes res=Yes log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Format()
    begin
        Act('round');
        Act('format');
        Act('evaluate');
        Observer.Expect('round|err', '');
        Observer.Expect('round|m0', 'ok=Yes res=1.23;1.2;3 log=[]');
        Observer.Expect('round|m1|err-same', 'Yes');
        Observer.Expect('round|m1', 'ok=Yes res=1.23;1.2;3 log=[]');
        Observer.Expect('round|m2|err-same', 'Yes');
        Observer.Expect('round|m2', 'ok=Yes res=1.23;1.2;3 log=[]');
        Observer.Expect('round|m3|err-same', 'Yes');
        Observer.Expect('round|m3', 'ok=Yes res=1.23;1.2;3 log=[]');
        Observer.Expect('format|err', '');
        Observer.Expect('format|m0', 'ok=Yes res=1,234.5;1,234.50;1234.5 log=[]');
        Observer.Expect('format|m1|err-same', 'Yes');
        Observer.Expect('format|m1', 'ok=Yes res=1,234.5;1,234.50;1234.5 log=[]');
        Observer.Expect('format|m2|err-same', 'Yes');
        Observer.Expect('format|m2', 'ok=Yes res=1,234.5;1,234.50;1234.5 log=[]');
        Observer.Expect('format|m3|err-same', 'Yes');
        Observer.Expect('format|m3', 'ok=Yes res=1,234.5;1,234.50;1234.5 log=[]');
        Observer.Expect('evaluate|err', '');
        Observer.Expect('evaluate|m0', 'ok=Yes res=125 log=[]');
        Observer.Expect('evaluate|m1|err-same', 'Yes');
        Observer.Expect('evaluate|m1', 'ok=Yes res=125 log=[]');
        Observer.Expect('evaluate|m2|err-same', 'Yes');
        Observer.Expect('evaluate|m2', 'ok=Yes res=125 log=[]');
        Observer.Expect('evaluate|m3|err-same', 'Yes');
        Observer.Expect('evaluate|m3', 'ok=Yes res=125 log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Captions()
    begin
        Act('fieldcap');
        Act('fieldcaptxt');
        Observer.Expect('fieldcap|err', '');
        Observer.Expect('fieldcap|m0', 'ok=Yes res=Caption three log=[]');
        Observer.Expect('fieldcap|m1|err-same', 'Yes');
        Observer.Expect('fieldcap|m1', 'ok=Yes res=Caption three log=[]');
        Observer.Expect('fieldcap|m2|err-same', 'Yes');
        Observer.Expect('fieldcap|m2', 'ok=Yes res=Caption three log=[]');
        Observer.Expect('fieldcap|m3|err-same', 'Yes');
        Observer.Expect('fieldcap|m3', 'ok=Yes res=Caption three log=[]');
        Observer.Expect('fieldcaptxt|err', '');
        Observer.Expect('fieldcaptxt|m0', 'ok=Yes res=Txt log=[]');
        Observer.Expect('fieldcaptxt|m1|err-same', 'Yes');
        Observer.Expect('fieldcaptxt|m1', 'ok=Yes res=Txt log=[]');
        Observer.Expect('fieldcaptxt|m2|err-same', 'Yes');
        Observer.Expect('fieldcaptxt|m2', 'ok=Yes res=Txt log=[]');
        Observer.Expect('fieldcaptxt|m3|err-same', 'Yes');
        Observer.Expect('fieldcaptxt|m3', 'ok=Yes res=Txt log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_Date()
    begin
        Act('datefilter');
        Act('datefiltertext');
        Observer.Expect('datefilter|err', '');
        Observer.Expect('datefilter|m0', 'ok=Yes res=>=01/01/20 log=[]');
        Observer.Expect('datefilter|m1|err-same', 'Yes');
        Observer.Expect('datefilter|m1', 'ok=Yes res=>=01/01/20 log=[]');
        Observer.Expect('datefilter|m2|err-same', 'Yes');
        Observer.Expect('datefilter|m2', 'ok=Yes res=>=01/01/20 log=[]');
        Observer.Expect('datefilter|m3|err-same', 'Yes');
        Observer.Expect('datefilter|m3', 'ok=Yes res=>=01/01/20 log=[]');
        Observer.Expect('datefiltertext|err', 'The filter "010120..311220" is not valid for the D field on the LT W Pt Row table. The format of the Date ''311220'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('datefiltertext|m0', 'ok=No res= log=[]');
        Observer.Expect('datefiltertext|m1|err-same', 'Yes');
        Observer.Expect('datefiltertext|m1', 'ok=No res= log=[MakeDateFilter(DateFilterText=311220) | MakeDateFilter(DateFilterText=010120..311220)]');
        Observer.Expect('datefiltertext|m2|err-same', 'Yes');
        Observer.Expect('datefiltertext|m2', 'ok=No res= log=[MakeDateFilter(DateFilterText=311220) | MakeDateFilter(DateFilterText=W:DateFilterText) | MakeDateFilter(DateFilterText=010120..311220) | MakeDateFilter(DateFilterText=W:DateFilterText)]');
        Observer.Expect('datefiltertext|m3|err-same', 'No');
        Observer.Expect('datefiltertext|m3', 'ok=Yes res=01/01/20..12/31/20 log=[MakeDateFilter(DateFilterText=311220)]');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_DateTime_Time()
    begin
        Act('datetimefilter');
        Act('timefilter');
        Observer.Expect('datetimefilter|err', '');
        Observer.Expect('datetimefilter|m0', 'ok=Yes res=>=01/01/20 12:00 PM log=[]');
        Observer.Expect('datetimefilter|m1|err-same', 'Yes');
        Observer.Expect('datetimefilter|m1', 'ok=Yes res=>=01/01/20 12:00 PM log=[]');
        Observer.Expect('datetimefilter|m2|err-same', 'Yes');
        Observer.Expect('datetimefilter|m2', 'ok=Yes res=>=01/01/20 12:00 PM log=[]');
        Observer.Expect('datetimefilter|m3|err-same', 'Yes');
        Observer.Expect('datetimefilter|m3', 'ok=Yes res=>=01/01/20 12:00 PM log=[]');
        Observer.Expect('timefilter|err', '');
        Observer.Expect('timefilter|m0', 'ok=Yes res=>=12:00:00 PM log=[]');
        Observer.Expect('timefilter|m1|err-same', 'Yes');
        Observer.Expect('timefilter|m1', 'ok=Yes res=>=12:00:00 PM log=[]');
        Observer.Expect('timefilter|m2|err-same', 'Yes');
        Observer.Expect('timefilter|m2', 'ok=Yes res=>=12:00:00 PM log=[]');
        Observer.Expect('timefilter|m3|err-same', 'Yes');
        Observer.Expect('timefilter|m3', 'ok=Yes res=>=12:00:00 PM log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Filter_View()
    begin
        Act('view');
        Observer.Expect('view|err', '');
        Observer.Expect('view|m0', 'ok=Yes res=01/01/20.. log=[]');
        Observer.Expect('view|m1|err-same', 'Yes');
        Observer.Expect('view|m1', 'ok=Yes res=01/01/20.. log=[]');
        Observer.Expect('view|m2|err-same', 'Yes');
        Observer.Expect('view|m2', 'ok=Yes res=01/01/20.. log=[]');
        Observer.Expect('view|m3|err-same', 'Yes');
        Observer.Expect('view|m3', 'ok=Yes res=01/01/20.. log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Bad_Date()
    begin
        Act('baddate');
        Act('baddate2');
        Observer.Expect('baddate|err', 'The filter "abc" is not valid for the D field on the LT W Pt Row table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('baddate|m0', 'ok=No res= log=[]');
        Observer.Expect('baddate|m1|err-same', 'Yes');
        Observer.Expect('baddate|m1', 'ok=No res= log=[MakeDateFilter(DateFilterText=abc)]');
        Observer.Expect('baddate|m2|err-same', 'Yes');
        Observer.Expect('baddate|m2', 'ok=No res= log=[MakeDateFilter(DateFilterText=abc) | MakeDateFilter(DateFilterText=W:DateFilterText)]');
        Observer.Expect('baddate|m3|err-same', 'No');
        Observer.Expect('baddate|m3', 'ok=Yes res=12/31/20 log=[MakeDateFilter(DateFilterText=abc)]');
        Observer.Expect('baddate2|err', 'The filter "010120..311220" is not valid for the D field on the LT W Pt Row table. The format of the Date ''311220'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('baddate2|m0', 'ok=No res= log=[]');
        Observer.Expect('baddate2|m1|err-same', 'Yes');
        Observer.Expect('baddate2|m1', 'ok=No res= log=[MakeDateFilter(DateFilterText=311220) | MakeDateFilter(DateFilterText=010120..311220)]');
        Observer.Expect('baddate2|m2|err-same', 'Yes');
        Observer.Expect('baddate2|m2', 'ok=No res= log=[MakeDateFilter(DateFilterText=311220) | MakeDateFilter(DateFilterText=W:DateFilterText) | MakeDateFilter(DateFilterText=010120..311220) | MakeDateFilter(DateFilterText=W:DateFilterText)]');
        Observer.Expect('baddate2|m3|err-same', 'No');
        Observer.Expect('baddate2|m3', 'ok=Yes res=01/01/20..12/31/20 log=[MakeDateFilter(DateFilterText=311220)]');
        Observer.Verify();
    end;

    [Test]
    procedure Bad_DateTime()
    begin
        Act('baddatetime');
        Observer.Expect('baddatetime|err', 'The filter "abc" is not valid for the DT field on the LT W Pt Row table. The value "abc" can''t be evaluated into type DateTime.');
        Observer.Expect('baddatetime|m0', 'ok=No res= log=[]');
        Observer.Expect('baddatetime|m1|err-same', 'Yes');
        Observer.Expect('baddatetime|m1', 'ok=No res= log=[MakeDateTimeFilter(DateTimeFilterText=abc)]');
        Observer.Expect('baddatetime|m2|err-same', 'Yes');
        Observer.Expect('baddatetime|m2', 'ok=No res= log=count=2');
        Observer.Expect('baddatetime|m3|err-same', 'No');
        Observer.Expect('baddatetime|m3', 'ok=Yes res=12/31/20 12:00 PM..12/31/20 12:00 PM log=[MakeDateTimeFilter(DateTimeFilterText=abc) | MakeDateTimeFilter(DateTimeFilterText=abc)]');
        Observer.Verify();
    end;

    [Test]
    procedure Bad_Time()
    begin
        Act('badtime');
        Observer.Expect('badtime|err', 'The filter "abc" is not valid for the T field on the LT W Pt Row table. The value "abc" can''t be evaluated into type Time.');
        Observer.Expect('badtime|m0', 'ok=No res= log=[]');
        Observer.Expect('badtime|m1|err-same', 'Yes');
        Observer.Expect('badtime|m1', 'ok=No res= log=[MakeTimeFilter(TimeFilterText=abc)]');
        Observer.Expect('badtime|m2|err-same', 'Yes');
        Observer.Expect('badtime|m2', 'ok=No res= log=[MakeTimeFilter(TimeFilterText=abc) | MakeTimeFilter(TimeFilterText=W:TimeFilterText)]');
        Observer.Expect('badtime|m3|err-same', 'No');
        Observer.Expect('badtime|m3', 'ok=Yes res=12:00:00 PM log=[MakeTimeFilter(TimeFilterText=abc)]');
        Observer.Verify();
    end;

    [Test]
    procedure Bad_Int()
    begin
        Act('badint');
        Observer.Expect('badint|err', 'The filter "abc" is not valid for the Id field on the LT W Pt Row table. The value "abc" can''t be evaluated into type Integer.');
        Observer.Expect('badint|m0', 'ok=No res= log=[]');
        Observer.Expect('badint|m1|err-same', 'Yes');
        Observer.Expect('badint|m1', 'ok=No res= log=[MakeIntFilter(IntFilterText=abc)]');
        Observer.Expect('badint|m2|err-same', 'Yes');
        Observer.Expect('badint|m2', 'ok=No res= log=[MakeIntFilter(IntFilterText=abc) | MakeIntFilter(IntFilterText=W:IntFilterText)]');
        Observer.Expect('badint|m3|err-same', 'No');
        Observer.Expect('badint|m3', 'ok=Yes res=5 log=[MakeIntFilter(IntFilterText=abc)]');
        Observer.Verify();
    end;

    [Test]
    procedure Bad_Decimal()
    begin
        Act('baddec');
        Observer.Expect('baddec|err', 'The filter "abc" is not valid for the Amount field on the LT W Pt Row table. The value "abc" can''t be evaluated into type Decimal.');
        Observer.Expect('baddec|m0', 'ok=No res= log=[]');
        Observer.Expect('baddec|m1|err-same', 'Yes');
        Observer.Expect('baddec|m1', 'ok=No res= log=[]');
        Observer.Expect('baddec|m2|err-same', 'Yes');
        Observer.Expect('baddec|m2', 'ok=No res= log=[]');
        Observer.Expect('baddec|m3|err-same', 'Yes');
        Observer.Expect('baddec|m3', 'ok=No res= log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Notifications()
    begin
        Act('mynotif');
        Act('mynotifoff');
        Observer.Expect('mynotif|err', '');
        Observer.Expect('mynotif|m0', 'ok=Yes res=Yes log=[]');
        Observer.Expect('mynotif|m1|err-same', 'Yes');
        Observer.Expect('mynotif|m1', 'ok=Yes res=Yes log=[]');
        Observer.Expect('mynotif|m2|err-same', 'Yes');
        Observer.Expect('mynotif|m2', 'ok=Yes res=Yes log=[]');
        Observer.Expect('mynotif|m3|err-same', 'Yes');
        Observer.Expect('mynotif|m3', 'ok=Yes res=Yes log=[]');
        Observer.Expect('mynotifoff|err', '');
        Observer.Expect('mynotifoff|m0', 'ok=Yes res=No log=[]');
        Observer.Expect('mynotifoff|m1|err-same', 'Yes');
        Observer.Expect('mynotifoff|m1', 'ok=Yes res=No log=[]');
        Observer.Expect('mynotifoff|m2|err-same', 'Yes');
        Observer.Expect('mynotifoff|m2', 'ok=Yes res=No log=[]');
        Observer.Expect('mynotifoff|m3|err-same', 'Yes');
        Observer.Expect('mynotifoff|m3', 'ok=Yes res=No log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure GetUrl_Copilot()
    begin
        Act('geturl');
        Act('copilotactive');
        Observer.Expect('geturl|err', '');
        Observer.Expect('geturl|m0', 'ok=Yes res=Yes log=[]');
        Observer.Expect('geturl|m1|err-same', 'Yes');
        Observer.Expect('geturl|m1', 'ok=Yes res=Yes log=[]');
        Observer.Expect('geturl|m2|err-same', 'Yes');
        Observer.Expect('geturl|m2', 'ok=Yes res=Yes log=[]');
        Observer.Expect('geturl|m3|err-same', 'Yes');
        Observer.Expect('geturl|m3', 'ok=Yes res=Yes log=[]');
        Observer.Expect('copilotactive|err', '');
        Observer.Expect('copilotactive|m0', 'ok=Yes res=No;No log=[]');
        Observer.Expect('copilotactive|m1|err-same', 'Yes');
        Observer.Expect('copilotactive|m1', 'ok=Yes res=No;No log=[]');
        Observer.Expect('copilotactive|m2|err-same', 'Yes');
        Observer.Expect('copilotactive|m2', 'ok=Yes res=No;No log=[]');
        Observer.Expect('copilotactive|m3|err-same', 'Yes');
        Observer.Expect('copilotactive|m3', 'ok=Yes res=No;No log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Privacy_Feature()
    begin
        Act('privstate');
        Act('feature');
        Observer.Expect('privstate|err', '');
        Observer.Expect('privstate|m0', 'ok=Yes res=Agreed log=[]');
        Observer.Expect('privstate|m1|err-same', 'Yes');
        Observer.Expect('privstate|m1', 'ok=Yes res=Agreed log=[]');
        Observer.Expect('privstate|m2|err-same', 'Yes');
        Observer.Expect('privstate|m2', 'ok=Yes res=Agreed log=[]');
        Observer.Expect('privstate|m3|err-same', 'Yes');
        Observer.Expect('privstate|m3', 'ok=Yes res=Agreed log=[]');
        Observer.Expect('feature|err', '');
        Observer.Expect('feature|m0', 'ok=Yes res=No log=[]');
        Observer.Expect('feature|m1|err-same', 'Yes');
        Observer.Expect('feature|m1', 'ok=Yes res=No log=[]');
        Observer.Expect('feature|m2|err-same', 'Yes');
        Observer.Expect('feature|m2', 'ok=Yes res=No log=[]');
        Observer.Expect('feature|m3|err-same', 'Yes');
        Observer.Expect('feature|m3', 'ok=Yes res=No log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure LegacyBar()
    begin
        Act('legacybar');
        Observer.Expect('legacybar|err', '');
        Observer.Expect('legacybar|m0', 'ok=Yes res=done log=[]');
        Observer.Expect('legacybar|m1|err-same', 'Yes');
        Observer.Expect('legacybar|m1', 'ok=Yes res=done log=[]');
        Observer.Expect('legacybar|m2|err-same', 'Yes');
        Observer.Expect('legacybar|m2', 'ok=Yes res=done log=[]');
        Observer.Expect('legacybar|m3|err-same', 'Yes');
        Observer.Expect('legacybar|m3', 'ok=Yes res=done log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Report_Xml()
    begin
        Act('saveasxml');
        Observer.Expect('saveasxml|err', '');
        Observer.Expect('saveasxml|m0', 'ok=Yes res=Yes log=[]');
        Observer.Expect('saveasxml|m1|err-same', 'Yes');
        Observer.Expect('saveasxml|m1', 'ok=Yes res=Yes log=[]');
        Observer.Expect('saveasxml|m2|err-same', 'Yes');
        Observer.Expect('saveasxml|m2', 'ok=Yes res=Yes log=[]');
        Observer.Expect('saveasxml|m3|err-same', 'Yes');
        Observer.Expect('saveasxml|m3', 'ok=Yes res=Yes log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure Report_Pdf()
    begin
        Act('saveaspdf');
        Observer.Expect('saveaspdf|err', '');
        Observer.Expect('saveaspdf|m0', 'ok=Yes res=Yes log=[]');
        Observer.Expect('saveaspdf|m1|err-same', 'Yes');
        Observer.Expect('saveaspdf|m1', 'ok=Yes res=Yes log=[]');
        Observer.Expect('saveaspdf|m2|err-same', 'Yes');
        Observer.Expect('saveaspdf|m2', 'ok=Yes res=Yes log=[]');
        Observer.Expect('saveaspdf|m3|err-same', 'Yes');
        Observer.Expect('saveaspdf|m3', 'ok=Yes res=Yes log=[]');
        Observer.Verify();
    end;

    [Test]
    procedure PageRun_Zero()
    begin
        Act('pagerun0');
        Observer.Expect('pagerun0|err', 'You tried to invoke the Page object with the ID 0 from the object LT W Pt Runner. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('pagerun0|m0', 'ok=No res= log=[]');
        Observer.Expect('pagerun0|m1|err-same', 'Yes');
        Observer.Expect('pagerun0|m1', 'ok=No res= log=[]');
        Observer.Expect('pagerun0|m2|err-same', 'Yes');
        Observer.Expect('pagerun0|m2', 'ok=No res= log=[]');
        Observer.Expect('pagerun0|m3|err-same', 'Yes');
        Observer.Expect('pagerun0|m3', 'ok=No res= log=[]');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Row: Record "LT W Pt Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row."Code Value" := 'ALPHA';
        Row.Txt := 'first';
        Row.Amount := 1234.5;
        Row.D := DMY2Date(15, 3, 2020);
        Row.DT := CreateDateTime(DMY2Date(15, 3, 2020), 130000T);
        Row.T := 130000T;
        Row.Cnt := 7;
        Row.Cap := 'X';
        Row.Insert();
    end;

    [Test]
    procedure TestPage_List()
    var
        Log: Codeunit "LT W Pt Log";
        List: TestPage "LT W Pt List";
        Mode: Integer;
    begin
        Seed();
        for Mode := 0 to 2 do begin
            Log.SetMode(Mode);
            Log.Reset();
            List.OpenView();
            Observer.Observe('open|m' + Format(Mode), Short(Log.Dump()));
            Observer.Observe('amount|m' + Format(Mode), List.AmountCtl.Value());
            Observer.Observe('log-after-amount|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            List.Filter.SetFilter(D, '>=' + Format(DMY2Date(1, 1, 2020)));
            Observer.Observe('datefilter|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            List.Filter.SetFilter(DT, '>=' + Format(CreateDateTime(DMY2Date(1, 1, 2020), 120000T)));
            Observer.Observe('datetimefilter|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            List.Filter.SetFilter(T, '>=' + Format(120000T));
            Observer.Observe('timefilter|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            List.Close();
            Observer.Observe('close|m' + Format(Mode), Short(Log.Dump()));
            Log.SetMode(0);
        end;
        Observer.Expect('open|m0', '[]');
        Observer.Expect('amount|m0', '1,234.50');
        Observer.Expect('log-after-amount|m0', '[]');
        Observer.Expect('datefilter|m0', '[]');
        Observer.Expect('datetimefilter|m0', '[]');
        Observer.Expect('timefilter|m0', '[]');
        Observer.Expect('close|m0', '[]');
        Observer.Expect('open|m1', '[]');
        Observer.Expect('amount|m1', '1,234.50');
        Observer.Expect('log-after-amount|m1', '[]');
        Observer.Expect('datefilter|m1', '[]');
        Observer.Expect('datetimefilter|m1', '[]');
        Observer.Expect('timefilter|m1', '[]');
        Observer.Expect('close|m1', '[]');
        Observer.Expect('open|m2', '[]');
        Observer.Expect('amount|m2', '1,234.50');
        Observer.Expect('log-after-amount|m2', '[]');
        Observer.Expect('datefilter|m2', '[]');
        Observer.Expect('datetimefilter|m2', '[]');
        Observer.Expect('timefilter|m2', '[]');
        Observer.Expect('close|m2', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_BadFilter()
    var
        Log: Codeunit "LT W Pt Log";
        List: TestPage "LT W Pt List";
    begin
        Seed();
        List.OpenView();
        Log.SetMode(1);
        Log.Reset();
        asserterror List.Filter.SetFilter(D, 'abc');
        Observer.ObserveError('baddate-m1');
        Observer.Observe('baddate-m1-log', Short(Log.Dump()));
        Log.SetMode(3);
        Log.Reset();
        List.Filter.SetFilter(D, 'abc');
        Observer.Observe('baddate-m3-log', Short(Log.Dump()));
        Observer.Observe('baddate-m3-filter', List.Filter.GetFilter(D));
        Observer.Observe('baddate-m3-rows', Format(List.First()));
        Log.SetMode(0);
        List.Close();
        Observer.Expect('baddate-m1|text', 'The filter "abc" is not valid for the D field on the LT W Pt Row table. The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('baddate-m1|code', 'Filter:CSide');
        Observer.Expect('baddate-m1-log', '[MakeDateFilter(DateFilterText=abc)]');
        Observer.Expect('baddate-m3-log', '[MakeDateFilter(DateFilterText=abc) | MakeDateFilter(DateFilterText=abc)]');
        Observer.Expect('baddate-m3-filter', '12/31/20');
        Observer.Expect('baddate-m3-rows', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TestPage_CardCue()
    var
        Log: Codeunit "LT W Pt Log";
        Card: TestPage "LT W Pt Card";
        Mode: Integer;
    begin
        Seed();
        for Mode := 0 to 2 do begin
            Log.SetMode(Mode);
            Log.Reset();
            Card.OpenEdit();
            Observer.Observe('open|m' + Format(Mode), Short(Log.Dump()));
            Observer.Observe('cue|m' + Format(Mode), Card.CntCue.Value());
            Observer.Observe('amount|m' + Format(Mode), Card.AmountCtl.Value());
            Observer.Observe('log-after-reads|m' + Format(Mode), Short(Log.Dump()));
            Log.Reset();
            Card.Close();
            Observer.Observe('close|m' + Format(Mode), Short(Log.Dump()));
            Log.SetMode(0);
        end;
        Observer.Expect('open|m0', '[]');
        Observer.Expect('cue|m0', '7');
        Observer.Expect('amount|m0', '1,234.50');
        Observer.Expect('log-after-reads|m0', '[]');
        Observer.Expect('close|m0', '[]');
        Observer.Expect('open|m1', '[GetCueStyle(TableId=69883,FieldNo=8,CueValue=0,StyleText=None) | GetCueStyle(TableId=69883,FieldNo=8,CueValue=7,StyleText=None)]');
        Observer.Expect('cue|m1', '7');
        Observer.Expect('amount|m1', '1,234.50');
        Observer.Expect('log-after-reads|m1', '[GetCueStyle(TableId=69883,FieldNo=8,CueValue=0,StyleText=None) | GetCueStyle(TableId=69883,FieldNo=8,CueValue=7,StyleText=None)]');
        Observer.Expect('close|m1', '[]');
        Observer.Expect('open|m2', '[GetCueStyle(TableId=69883,FieldNo=8,CueValue=0,StyleText=None) | GetCueStyle(TableId=69883,FieldNo=8,CueValue=7,StyleText=None)]');
        Observer.Expect('cue|m2', '7');
        Observer.Expect('amount|m2', '1,234.50');
        Observer.Expect('log-after-reads|m2', '[GetCueStyle(TableId=69883,FieldNo=8,CueValue=0,StyleText=None) | GetCueStyle(TableId=69883,FieldNo=8,CueValue=7,StyleText=None)]');
        Observer.Expect('close|m2', '[]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('FilterPageH')]
    procedure FilterPageBuilder_Run()
    var
        Log: Codeunit "LT W Pt Log";
        Fpb: FilterPageBuilder;
        PtRow: Record "LT W Pt Row";
        Mode: Integer;
        Ok: Boolean;
    begin
        for Mode := 0 to 2 do begin
            Log.SetMode(Mode);
            Log.Reset();
            Clear(Fpb);
            Fpb.AddTable('Rows', Database::"LT W Pt Row");
            Fpb.AddField('Rows', PtRow.D);
            Fpb.AddField('Rows', PtRow.Cap);
            Fpb.SetView('Rows', 'WHERE(D=FILTER(010120..))');
            Ok := Fpb.RunModal();
            Observer.Observe('runmodal|m' + Format(Mode), Format(Ok));
            Observer.Observe('view|m' + Format(Mode), Fpb.GetView('Rows', false));
            Observer.Observe('log-after-view|m' + Format(Mode), Short(Log.Dump()));
            Log.SetMode(0);
        end;
        Observer.Expect('runmodal|m0', 'Yes');
        Observer.Expect('view|m0', 'VERSION(1) SORTING(Field1) WHERE(Field5=1(2020-01-01..))');
        Observer.Expect('log-after-view|m0', '[]');
        Observer.Expect('runmodal|m1', 'Yes');
        Observer.Expect('view|m1', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('log-after-view|m1', '[]');
        Observer.Expect('runmodal|m2', 'Yes');
        Observer.Expect('view|m2', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('log-after-view|m2', '[]');
        Observer.Verify();
    end;

    [FilterPageHandler]
    procedure FilterPageH(var Rec: RecordRef): Boolean
    begin
        exit(true);
    end;
}
