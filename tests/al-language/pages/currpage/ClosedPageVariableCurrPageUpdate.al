// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 71380, page 71381, codeunit 71382
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a Page variable whose page was run modally and closed (and one that was never run): calling a procedure that uses CurrPage.Update(false); afterwards: error text and code, or nothing.

table 71380 "LT Closed Update Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 71381 "LT Closed Update Page"
{
    PageType = List;
    SourceTable = "LT Closed Update Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(IdCtl; Rec.Id) { ApplicationArea = All; }
            }
        }
    }

    procedure UseCurrPage(var Log: Text)
    var
        Sel: Record "LT Closed Update Row";
    begin
        Log := 'start';
        CurrPage.Update(false);
        Log += ' end';
    end;
}

codeunit 71382 "LT Closed Update Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryUse(var P: Page "LT Closed Update Page"; var Log: Text)
    begin
        P.UseCurrPage(Log);
    end;

    [ModalPageHandler]
    procedure CloseModal(var P: TestPage "LT Closed Update Page")
    begin
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('CloseModal')]
    procedure Update_AfterModalClosed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Closed Update Row";
        P: Page "LT Closed Update Page";
        Log: Text;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        asserterror P.RunModal();
        Observer.ObserveError('af81');
        Ok := TryUse(P, Log);
        Observer.Observe('call succeeded', Format(Ok));
        Observer.Observe('error text', GetLastErrorText());
        Observer.Observe('error code', GetLastErrorCode());
        Observer.Observe('progress', Log);
        Observer.Expect('af81|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af81|code', 'TestActionNotFound');
        Observer.Expect('call succeeded', 'Yes');
        Observer.Expect('error text', '');
        Observer.Expect('error code', '');
        Observer.Expect('progress', 'start end');
        Observer.Verify();
    end;

    [Test]
    procedure Update_NeverRun()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT Closed Update Page";
        Log: Text;
        Ok: Boolean;
    begin
        Ok := TryUse(P, Log);
        Observer.Observe('call succeeded', Format(Ok));
        Observer.Observe('error text', GetLastErrorText());
        Observer.Observe('error code', GetLastErrorCode());
        Observer.Observe('progress', Log);
        Observer.Expect('call succeeded', 'Yes');
        Observer.Expect('error text', '');
        Observer.Expect('error code', '');
        Observer.Expect('progress', 'start end');
        Observer.Verify();
    end;
}
