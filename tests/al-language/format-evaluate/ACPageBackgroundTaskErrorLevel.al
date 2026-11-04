// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/pagebackgroundtaskerrorlevel/pagebackgroundtaskerrorlevel-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the PageBackgroundTaskErrorLevel option type: Format of every member as text (Format 0,0), as ordinal (Format 0,2) and as number text (Format 0,1), a case statement over every member, . The type is option-like: AsInteger does not exist and an Integer is not assignable (AL0132 and AL0122 at compile time).
//   Evaluate(Type, Text) is not probed: a test that calls it ends the test session ("hub connection closed") on BC 29, like PageStyle (types/lt-page-style/PageStyle.al).
//   Settles #626 items 11 to 15 for PageBackgroundTaskErrorLevel.
// BC versions: 27, 28, 29

codeunit 77516 "LT AC PBT Error Level Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_PageBackgroundTaskErrorLevel_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin

        Observer.Observe('text_Error', Format(PageBackgroundTaskErrorLevel::Error));
        Observer.Observe('text_Warning', Format(PageBackgroundTaskErrorLevel::Warning));
        Observer.Observe('text_Ignore', Format(PageBackgroundTaskErrorLevel::Ignore));
        Observer.Observe('ordinal_Error', Format(PageBackgroundTaskErrorLevel::Error, 0, 2));
        Observer.Observe('ordinal_Warning', Format(PageBackgroundTaskErrorLevel::Warning, 0, 2));
        Observer.Observe('ordinal_Ignore', Format(PageBackgroundTaskErrorLevel::Ignore, 0, 2));
        Observer.Observe('number_Error', Format(PageBackgroundTaskErrorLevel::Error, 0, 1));
        Observer.Observe('number_Warning', Format(PageBackgroundTaskErrorLevel::Warning, 0, 1));
        Observer.Observe('number_Ignore', Format(PageBackgroundTaskErrorLevel::Ignore, 0, 1));
        Observer.Expect('text_Error', 'Error');
        Observer.Expect('text_Warning', 'Warning');
        Observer.Expect('text_Ignore', 'Ignore');
        Observer.Expect('ordinal_Error', '0');
        Observer.Expect('ordinal_Warning', '10');
        Observer.Expect('ordinal_Ignore', '20');
        Observer.Expect('number_Error', 'Error');
        Observer.Expect('number_Warning', 'Warning');
        Observer.Expect('number_Ignore', 'Ignore');
        Observer.Verify();
    end;

    [Test]
    procedure AC_PageBackgroundTaskErrorLevel_Variable()
    var
        Observer: Codeunit "Probe Observer";
        V: PageBackgroundTaskErrorLevel;
    begin

        Observer.Observe('default', Format(V));
        Observer.Observe('default_ordinal', Format(V, 0, 2));
        V := PageBackgroundTaskErrorLevel::Ignore;
        Observer.Observe('last', Format(V));
        Observer.Observe('last_ordinal', Format(V, 0, 2));
        Observer.Observe('eq_last', Format(V = PageBackgroundTaskErrorLevel::Ignore));
        Observer.Observe('eq_first', Format(V = PageBackgroundTaskErrorLevel::Error));
        Clear(V);
        Observer.Observe('cleared', Format(V));
        Observer.Expect('default', 'Error');
        Observer.Expect('default_ordinal', '0');
        Observer.Expect('last', 'Ignore');
        Observer.Expect('last_ordinal', '20');
        Observer.Expect('eq_last', 'Yes');
        Observer.Expect('eq_first', 'No');
        Observer.Expect('cleared', 'Error');
        Observer.Verify();
    end;

    [Test]
    procedure AC_PageBackgroundTaskErrorLevel_Case()
    var
        Observer: Codeunit "Probe Observer";
        V: PageBackgroundTaskErrorLevel;
    begin
        V := PageBackgroundTaskErrorLevel::Error;
        Observer.Observe('case_Error', CaseName(V));
        V := PageBackgroundTaskErrorLevel::Warning;
        Observer.Observe('case_Warning', CaseName(V));
        V := PageBackgroundTaskErrorLevel::Ignore;
        Observer.Observe('case_Ignore', CaseName(V));
        Observer.Expect('case_Error', 'is_Error');
        Observer.Expect('case_Warning', 'is_Warning');
        Observer.Expect('case_Ignore', 'is_Ignore');
        Observer.Verify();
    end;

    local procedure CaseName(V: PageBackgroundTaskErrorLevel): Text
    begin
        case V of
            PageBackgroundTaskErrorLevel::Error:
                exit('is_Error');
            PageBackgroundTaskErrorLevel::Warning:
                exit('is_Warning');
            PageBackgroundTaskErrorLevel::Ignore:
                exit('is_Ignore');
            else
                exit('other');
        end;
    end;
}
