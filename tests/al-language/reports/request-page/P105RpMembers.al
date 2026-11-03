// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-request-page
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; SingleInstance log 72239 is used only by test codeunit 72241
// Facts: RequestPage.Activate, Editable (get, set false, restore), LookupMode (get, set), ObjectId (names and ids) inside a request page field OnValidate that the handler triggers with SetValue; OnOpenPage reads the same members too

codeunit 72239 "LT P105 RpMemLog"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

report 72240 "LT P105 RpMem"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(IntCtl; IntVal)
                {
                    ApplicationArea = All;
                    Caption = 'Integer Control';

                    trigger OnValidate()
                    begin
                        case IntVal of
                            1:
                                begin
                                    L.Add('editable=' + Format(RequestOptionsPage.Editable()));
                                    RequestOptionsPage.Editable(false);
                                    L.Add('editable after false=' + Format(RequestOptionsPage.Editable()));
                                    RequestOptionsPage.Editable(true);
                                    L.Add('editable after true=' + Format(RequestOptionsPage.Editable()));
                                end;
                            2:
                                begin
                                    L.Add('lookupmode=' + Format(RequestOptionsPage.LookupMode()));
                                    RequestOptionsPage.LookupMode(true);
                                    L.Add('lookupmode after true=' + Format(RequestOptionsPage.LookupMode()));
                                    RequestOptionsPage.LookupMode(false);
                                    L.Add('lookupmode after false=' + Format(RequestOptionsPage.LookupMode()));
                                end;
                            3:
                                begin
                                    L.Add('objectid default=' + RequestOptionsPage.ObjectId());
                                    L.Add('objectid names=' + RequestOptionsPage.ObjectId(true));
                                    L.Add('objectid ids=' + RequestOptionsPage.ObjectId(false));
                                end;
                            4:
                                begin
                                    RequestOptionsPage.Activate();
                                    L.Add('activate done');
                                    RequestOptionsPage.Activate(true);
                                    L.Add('activate refresh done');
                                    RequestOptionsPage.Activate(false);
                                    L.Add('activate no refresh done');
                                end;
                        end;
                    end;
                }
            }
        }
    }

    var
        IntVal: Integer;
        L: Codeunit "LT P105 RpMemLog";
}

codeunit 72241 "LT P105 RpMem Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT P105 RpMemLog";
        Helper: Codeunit "LT P105 Helper";

    [Test]
    [HandlerFunctions('EditableHandler')]
    procedure P105_RequestPage_Editable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RpMem");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'editable=Yes;editable after false=No;editable after true=Yes;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure EditableHandler(var RP: TestRequestPage "LT P105 RpMem")
    begin
        RP.IntCtl.SetValue(1);
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('LookupHandler')]
    procedure P105_RequestPage_LookupMode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RpMem");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'lookupmode=No;lookupmode after true=Yes;lookupmode after false=No;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure LookupHandler(var RP: TestRequestPage "LT P105 RpMem")
    begin
        RP.IntCtl.SetValue(2);
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ObjectIdHandler')]
    procedure P105_RequestPage_ObjectId()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        Report.Run(Report::"LT P105 RpMem");
        Observer.Observe('log', L.Take());
        Observer.Expect('log', 'objectid default=Page LT P105 RpMem;objectid names=Page LT P105 RpMem;objectid ids=Page 72240;');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ObjectIdHandler(var RP: TestRequestPage "LT P105 RpMem")
    begin
        RP.IntCtl.SetValue(3);
        RP.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('ActivateHandler')]
    procedure P105_RequestPage_Activate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        L.Take();
        asserterror Report.Run(Report::"LT P105 RpMem");
        Observer.ObserveError('af175');
        Observer.Observe('log', L.Take());
        Observer.Expect('af175|text', 'Unhandled UI: Page 72240');
        Observer.Expect('af175|code', 'ClientPageAbort:FormAbort');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure ActivateHandler(var RP: TestRequestPage "LT P105 RpMem")
    begin
        RP.IntCtl.SetValue(4);
        RP.Cancel().Invoke();
    end;
}
