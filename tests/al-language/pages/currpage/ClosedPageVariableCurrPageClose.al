// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-class
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 71383, page 71384, codeunit 71385
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: a Page variable whose page was run modally and closed (and one that was never run): calling a procedure that uses CurrPage.Close(); afterwards: error text and code, or nothing.

table 71383 "LT Closed Close Row"
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

page 71384 "LT Closed Close Page"
{
    PageType = List;
    SourceTable = "LT Closed Close Row";
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
        Sel: Record "LT Closed Close Row";
    begin
        Log := 'start';
        CurrPage.Close();
        Log += ' end';
    end;
}

codeunit 71385 "LT Closed Close Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryUse(var P: Page "LT Closed Close Page"; var Log: Text)
    begin
        P.UseCurrPage(Log);
    end;

    [ModalPageHandler]
    procedure CloseModal(var P: TestPage "LT Closed Close Page")
    begin
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('CloseModal')]
    procedure Close_AfterModalClosed()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Closed Close Row";
        P: Page "LT Closed Close Page";
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
    procedure Close_NeverRun()
    var
        Observer: Codeunit "Probe Observer";
        P: Page "LT Closed Close Page";
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
