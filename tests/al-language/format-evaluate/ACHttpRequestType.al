// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequesttype/httprequesttype-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the HttpRequestType option type: Format of every member as text (Format 0,0), as ordinal (Format 0,2) and as number text (Format 0,1), a case statement over every member, . The type is option-like: AsInteger does not exist and an Integer is not assignable (AL0132 and AL0122 at compile time).
//   Evaluate(Type, Text) is not probed: a test that calls it ends the test session ("hub connection closed") on BC 29, like PageStyle (types/lt-page-style/PageStyle.al).
//   Settles #626 items 11 to 15 for HttpRequestType.
// BC versions: 27, 28, 29

codeunit 77510 "LT AC HttpReqType Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_HttpRequestType_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin

        Observer.Observe('text_Unknown', Format(HttpRequestType::Unknown));
        Observer.Observe('text_Get', Format(HttpRequestType::Get));
        Observer.Observe('text_Delete', Format(HttpRequestType::Delete));
        Observer.Observe('text_Post', Format(HttpRequestType::Post));
        Observer.Observe('text_Put', Format(HttpRequestType::Put));
        Observer.Observe('text_Patch', Format(HttpRequestType::Patch));
        Observer.Observe('text_Options', Format(HttpRequestType::Options));
        Observer.Observe('text_Head', Format(HttpRequestType::Head));
        Observer.Observe('text_Connect', Format(HttpRequestType::Connect));
        Observer.Observe('text_Trace', Format(HttpRequestType::Trace));
        Observer.Observe('ordinal_Unknown', Format(HttpRequestType::Unknown, 0, 2));
        Observer.Observe('ordinal_Get', Format(HttpRequestType::Get, 0, 2));
        Observer.Observe('ordinal_Delete', Format(HttpRequestType::Delete, 0, 2));
        Observer.Observe('ordinal_Post', Format(HttpRequestType::Post, 0, 2));
        Observer.Observe('ordinal_Put', Format(HttpRequestType::Put, 0, 2));
        Observer.Observe('ordinal_Patch', Format(HttpRequestType::Patch, 0, 2));
        Observer.Observe('ordinal_Options', Format(HttpRequestType::Options, 0, 2));
        Observer.Observe('ordinal_Head', Format(HttpRequestType::Head, 0, 2));
        Observer.Observe('ordinal_Connect', Format(HttpRequestType::Connect, 0, 2));
        Observer.Observe('ordinal_Trace', Format(HttpRequestType::Trace, 0, 2));
        Observer.Observe('number_Unknown', Format(HttpRequestType::Unknown, 0, 1));
        Observer.Observe('number_Get', Format(HttpRequestType::Get, 0, 1));
        Observer.Observe('number_Delete', Format(HttpRequestType::Delete, 0, 1));
        Observer.Observe('number_Post', Format(HttpRequestType::Post, 0, 1));
        Observer.Observe('number_Put', Format(HttpRequestType::Put, 0, 1));
        Observer.Observe('number_Patch', Format(HttpRequestType::Patch, 0, 1));
        Observer.Observe('number_Options', Format(HttpRequestType::Options, 0, 1));
        Observer.Observe('number_Head', Format(HttpRequestType::Head, 0, 1));
        Observer.Observe('number_Connect', Format(HttpRequestType::Connect, 0, 1));
        Observer.Observe('number_Trace', Format(HttpRequestType::Trace, 0, 1));
        Observer.Expect('text_Unknown', 'Unknown');
        Observer.Expect('text_Get', 'Get');
        Observer.Expect('text_Delete', 'Delete');
        Observer.Expect('text_Post', 'Post');
        Observer.Expect('text_Put', 'Put');
        Observer.Expect('text_Patch', 'Patch');
        Observer.Expect('text_Options', 'Options');
        Observer.Expect('text_Head', 'Head');
        Observer.Expect('text_Connect', 'Connect');
        Observer.Expect('text_Trace', 'Trace');
        Observer.Expect('ordinal_Unknown', '0');
        Observer.Expect('ordinal_Get', '1');
        Observer.Expect('ordinal_Delete', '2');
        Observer.Expect('ordinal_Post', '3');
        Observer.Expect('ordinal_Put', '4');
        Observer.Expect('ordinal_Patch', '5');
        Observer.Expect('ordinal_Options', '6');
        Observer.Expect('ordinal_Head', '7');
        Observer.Expect('ordinal_Connect', '8');
        Observer.Expect('ordinal_Trace', '9');
        Observer.Expect('number_Unknown', 'Unknown');
        Observer.Expect('number_Get', 'Get');
        Observer.Expect('number_Delete', 'Delete');
        Observer.Expect('number_Post', 'Post');
        Observer.Expect('number_Put', 'Put');
        Observer.Expect('number_Patch', 'Patch');
        Observer.Expect('number_Options', 'Options');
        Observer.Expect('number_Head', 'Head');
        Observer.Expect('number_Connect', 'Connect');
        Observer.Expect('number_Trace', 'Trace');
        Observer.Verify();
    end;

    [Test]
    procedure AC_HttpRequestType_Variable()
    var
        Observer: Codeunit "Probe Observer";
        V: HttpRequestType;
    begin

        Observer.Observe('default', Format(V));
        Observer.Observe('default_ordinal', Format(V, 0, 2));
        V := HttpRequestType::Trace;
        Observer.Observe('last', Format(V));
        Observer.Observe('last_ordinal', Format(V, 0, 2));
        Observer.Observe('eq_last', Format(V = HttpRequestType::Trace));
        Observer.Observe('eq_first', Format(V = HttpRequestType::Unknown));
        Clear(V);
        Observer.Observe('cleared', Format(V));
        Observer.Expect('default', 'Unknown');
        Observer.Expect('default_ordinal', '0');
        Observer.Expect('last', 'Trace');
        Observer.Expect('last_ordinal', '9');
        Observer.Expect('eq_last', 'Yes');
        Observer.Expect('eq_first', 'No');
        Observer.Expect('cleared', 'Unknown');
        Observer.Verify();
    end;

    [Test]
    procedure AC_HttpRequestType_Case()
    var
        Observer: Codeunit "Probe Observer";
        V: HttpRequestType;
    begin
        V := HttpRequestType::Unknown;
        Observer.Observe('case_Unknown', CaseName(V));
        V := HttpRequestType::Get;
        Observer.Observe('case_Get', CaseName(V));
        V := HttpRequestType::Delete;
        Observer.Observe('case_Delete', CaseName(V));
        V := HttpRequestType::Post;
        Observer.Observe('case_Post', CaseName(V));
        V := HttpRequestType::Put;
        Observer.Observe('case_Put', CaseName(V));
        V := HttpRequestType::Patch;
        Observer.Observe('case_Patch', CaseName(V));
        V := HttpRequestType::Options;
        Observer.Observe('case_Options', CaseName(V));
        V := HttpRequestType::Head;
        Observer.Observe('case_Head', CaseName(V));
        V := HttpRequestType::Connect;
        Observer.Observe('case_Connect', CaseName(V));
        V := HttpRequestType::Trace;
        Observer.Observe('case_Trace', CaseName(V));
        Observer.Expect('case_Unknown', 'is_Unknown');
        Observer.Expect('case_Get', 'is_Get');
        Observer.Expect('case_Delete', 'is_Delete');
        Observer.Expect('case_Post', 'is_Post');
        Observer.Expect('case_Put', 'is_Put');
        Observer.Expect('case_Patch', 'is_Patch');
        Observer.Expect('case_Options', 'is_Options');
        Observer.Expect('case_Head', 'is_Head');
        Observer.Expect('case_Connect', 'is_Connect');
        Observer.Expect('case_Trace', 'is_Trace');
        Observer.Verify();
    end;

    local procedure CaseName(V: HttpRequestType): Text
    begin
        case V of
            HttpRequestType::Unknown:
                exit('is_Unknown');
            HttpRequestType::Get:
                exit('is_Get');
            HttpRequestType::Delete:
                exit('is_Delete');
            HttpRequestType::Post:
                exit('is_Post');
            HttpRequestType::Put:
                exit('is_Put');
            HttpRequestType::Patch:
                exit('is_Patch');
            HttpRequestType::Options:
                exit('is_Options');
            HttpRequestType::Head:
                exit('is_Head');
            HttpRequestType::Connect:
                exit('is_Connect');
            HttpRequestType::Trace:
                exit('is_Trace');
            else
                exit('other');
        end;
    end;
}
