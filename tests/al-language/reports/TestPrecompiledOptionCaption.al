// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optioncaption-property
// Scope: in-scope
// Fixtures used: Base Application report 91 "Export Consolidation" and page 6520 "Item Tracing"
//
// An Option control's OptionCaption decides what TestPage.<field>.SetValue accepts and what
// .Value() answers, on a request page and on an ordinary page alike, including when the
// object reaches the test precompiled inside a dependency app. Each claim uses a caption that
// differs from the option member's name, so a runtime that falls back to member names cannot
// satisfy it:
//   * report 91's FileFormat: members "Version 4.00 or Later (.xml)", "Version 3.70 or
//     Earlier (.txt)", "Version F&O"; OptionCaption ends 'Dynamics 365 Finance (.txt)'.
//   * page 6520's TraceMethod: members "Origin->Usage", "Usage->Origin"; OptionCaption
//     'Origin -> Usage,Usage -> Origin'. OnOpenPage sets it to "Usage->Origin".
// A caption that is none of the option's captions is refused ("Your entry of '...' is not an
// acceptable value"). What Value() answers after that refusal is deliberately not pinned.

codeunit 67575 "Precompiled Option Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CaptionToSet: Text;
        SeenValue: Text;
        SeenError: Text;
        HandlerRan: Boolean;

    local procedure Initialize()
    begin
        CaptionToSet := '';
        SeenValue := '';
        SeenError := '';
        HandlerRan := false;
    end;

    [Test]
    [HandlerFunctions('SetFileFormatHandler')]
    procedure RequestPage_SetValueByCaption_SelectsThatOption()
    begin
        Initialize();
        CaptionToSet := 'Dynamics 365 Finance (.txt)';

        Report.Run(Report::"Export Consolidation");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual('Dynamics 365 Finance (.txt)', SeenValue,
            'SetValue with the third OptionCaption must select the third option, read back by its caption');
    end;

    [Test]
    [HandlerFunctions('SetFileFormatHandler')]
    procedure RequestPage_SetValueBySecondCaption_SelectsThatOption()
    begin
        Initialize();
        CaptionToSet := 'Version 3.70 or Earlier (.txt)';

        Report.Run(Report::"Export Consolidation");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual('Version 3.70 or Earlier (.txt)', SeenValue,
            'SetValue with the second OptionCaption must select the second option');
    end;

    [Test]
    [HandlerFunctions('InvalidFileFormatHandler')]
    procedure RequestPage_SetValueByUnknownCaption_IsRefused()
    begin
        Initialize();

        Report.Run(Report::"Export Consolidation");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        // BC wraps this in "Validation error for Field: FileFormat,  Message = '...'"; the
        // assertion pins the refusal itself.
        Assert.IsTrue(StrPos(SeenError, 'Your entry of ''Not A Format'' is not an acceptable value') > 0,
            'SetValue with a caption the option does not declare must be refused; got: ' + SeenError);
    end;

    [Test]
    procedure Page_ValueReadsTheOptionCaption()
    var
        ItemTracing: TestPage "Item Tracing";
    begin
        ItemTracing.OpenEdit();

        Assert.AreEqual('Usage -> Origin', ItemTracing.TraceMethod.Value(),
            'OnOpenPage sets TraceMethod to "Usage->Origin"; Value() must answer its OptionCaption');
        ItemTracing.Close();
    end;

    [Test]
    procedure Page_SetValueByCaption_SelectsThatOption()
    var
        ItemTracing: TestPage "Item Tracing";
    begin
        ItemTracing.OpenEdit();

        ItemTracing.TraceMethod.SetValue('Origin -> Usage');

        Assert.AreEqual('Origin -> Usage', ItemTracing.TraceMethod.Value(),
            'SetValue with the first OptionCaption must select "Origin->Usage", read back by its caption');
        ItemTracing.Close();
    end;

    [RequestPageHandler]
    procedure SetFileFormatHandler(var RequestPage: TestRequestPage "Export Consolidation")
    begin
        HandlerRan := true;
        RequestPage.FileFormat.SetValue(CaptionToSet);
        SeenValue := RequestPage.FileFormat.Value();
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure InvalidFileFormatHandler(var RequestPage: TestRequestPage "Export Consolidation")
    begin
        HandlerRan := true;
        asserterror RequestPage.FileFormat.SetValue('Not A Format');
        SeenError := GetLastErrorText();
        RequestPage.Cancel().Invoke();
    end;
}
