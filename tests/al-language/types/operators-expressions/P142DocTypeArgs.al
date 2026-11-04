// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74560 "LT P142 DocType Args"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Dt: XmlDocumentType;

    [TryFunction]
    local procedure TryCreate2(N: Text; P: Text)
    begin
        Dt := XmlDocumentType.Create(N, P);
    end;

    [TryFunction]
    local procedure TryCreate1(N: Text)
    begin
        Dt := XmlDocumentType.Create(N);
    end;

    [TryFunction]
    local procedure TryCreate3(N: Text; P: Text; S: Text)
    begin
        Dt := XmlDocumentType.Create(N, P, S);
    end;

    [TryFunction]
    local procedure TryGetName(var R: Text)
    begin
        Dt.GetName(R);
    end;

    [TryFunction]
    local procedure TryGetPublic(var R: Text)
    begin
        Dt.GetPublicId(R);
    end;

    [TryFunction]
    local procedure TryGetSystem(var R: Text)
    begin
        Dt.GetSystemId(R);
    end;

    [TryFunction]
    local procedure TryGetSubset(var R: Text)
    begin
        Dt.GetInternalSubset(R);
    end;

    [TryFunction]
    local procedure TryWrite(var R: Text)
    begin
        Dt.WriteTo(R);
    end;

    [TryFunction]
    local procedure TrySetName(V: Text; var Ret: Boolean)
    begin
        Ret := Dt.SetName(V);
    end;

    [TryFunction]
    local procedure TrySetPublic(V: Text; var Ret: Boolean)
    begin
        Ret := Dt.SetPublicId(V);
    end;

    [TryFunction]
    local procedure TrySetSystem(V: Text; var Ret: Boolean)
    begin
        Ret := Dt.SetSystemId(V);
    end;

    [TryFunction]
    local procedure TrySetSubset(V: Text; var Ret: Boolean)
    begin
        Ret := Dt.SetInternalSubset(V);
    end;

    local procedure Getter(var Observer: Codeunit "Probe Observer"; Name: Text; Which: Integer)
    var
        R: Text;
        Ok: Boolean;
    begin
        R := 'unset';
        case Which of
            1:
                Ok := TryGetName(R);
            2:
                Ok := TryGetPublic(R);
            3:
                Ok := TryGetSystem(R);
            4:
                Ok := TryGetSubset(R);
            5:
                Ok := TryWrite(R);
        end;
        if Ok then
            Observer.Observe(Name, '[' + R + ']')
        else
            Observer.Observe(Name, 'error:' + CopyStr(GetLastErrorText(), 1, 300) + '|' + GetLastErrorCode());
    end;

    local procedure AllGetters(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        Getter(Observer, Prefix + 'name', 1);
        Getter(Observer, Prefix + 'public', 2);
        Getter(Observer, Prefix + 'system', 3);
        Getter(Observer, Prefix + 'subset', 4);
        Getter(Observer, Prefix + 'writeto', 5);
    end;

    local procedure Setter(var Observer: Codeunit "Probe Observer"; Name: Text; Which: Integer; V: Text)
    var
        Ret: Boolean;
        Ok: Boolean;
    begin
        case Which of
            1:
                Ok := TrySetName(V, Ret);
            2:
                Ok := TrySetPublic(V, Ret);
            3:
                Ok := TrySetSystem(V, Ret);
            4:
                Ok := TrySetSubset(V, Ret);
        end;
        if Ok then
            Observer.Observe(Name, 'ok ret=' + Format(Ret))
        else
            Observer.Observe(Name, 'error:' + CopyStr(GetLastErrorText(), 1, 300) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P142_Create_TwoArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('create2', Format(TryCreate2('html', 'pub')));
        Observer.ObserveError('create2');
        AllGetters(Observer, 'c2_');
        Observer.Observe('create2_empty_public', Format(TryCreate2('html', '')));
        Observer.ObserveError('create2_empty_public');
        AllGetters(Observer, 'c2e_');
        Observer.Observe('create2_empty_name', Format(TryCreate2('', 'pub')));
        Observer.ObserveError('create2_empty_name');
        Observer.Expect('create2', 'Yes');
        Observer.Expect('create2|text', '');
        Observer.Expect('create2|code', '');
        Observer.Expect('c2_name', '[html]');
        Observer.Expect('c2_public', '[pub]');
        Observer.Expect('c2_system', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.|MemberNotInitialized');
        Observer.Expect('c2_subset', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.|MemberNotInitialized');
        Observer.Expect('c2_writeto', '[<!DOCTYPE html PUBLIC "pub" "">]');
        Observer.Expect('create2_empty_public', 'Yes');
        Observer.Expect('create2_empty_public|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.');
        Observer.Expect('create2_empty_public|code', 'MemberNotInitialized');
        Observer.Expect('c2e_name', '[html]');
        Observer.Expect('c2e_public', '[]');
        Observer.Expect('c2e_system', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.|MemberNotInitialized');
        Observer.Expect('c2e_subset', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.|MemberNotInitialized');
        Observer.Expect('c2e_writeto', '[<!DOCTYPE html PUBLIC "" "">]');
        Observer.Expect('create2_empty_name', 'No');
        Observer.Expect('create2_empty_name|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('create2_empty_name|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure P142_Setters_On_OneArgument()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('create1', Format(TryCreate1('html')));
        Setter(Observer, 'set_name', 1, 'body');
        Setter(Observer, 'set_public', 2, 'pub');
        Setter(Observer, 'set_system', 3, 'x.dtd');
        Setter(Observer, 'set_subset', 4, '<!ELEMENT html EMPTY>');
        AllGetters(Observer, 'after_');
        Observer.Expect('create1', 'Yes');
        Observer.Expect('set_name', 'ok ret=Yes');
        Observer.Expect('set_public', 'ok ret=Yes');
        Observer.Expect('set_system', 'ok ret=Yes');
        Observer.Expect('set_subset', 'ok ret=Yes');
        Observer.Expect('after_name', '[body]');
        Observer.Expect('after_public', '[pub]');
        Observer.Expect('after_system', '[x.dtd]');
        Observer.Expect('after_subset', '[<!ELEMENT html EMPTY>]');
        Observer.Expect('after_writeto', '[<!DOCTYPE body PUBLIC "pub" "x.dtd"[<!ELEMENT html EMPTY>]>]');
        Observer.Verify();
    end;

    [Test]
    procedure P142_Setters_On_TwoArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('create2', Format(TryCreate2('html', 'pub')));
        Setter(Observer, 'set_name', 1, 'body');
        Setter(Observer, 'set_public', 2, 'pub2');
        Setter(Observer, 'set_system', 3, 'x.dtd');
        Setter(Observer, 'set_subset', 4, '<!ELEMENT html EMPTY>');
        AllGetters(Observer, 'after_');
        Observer.Expect('create2', 'Yes');
        Observer.Expect('set_name', 'ok ret=Yes');
        Observer.Expect('set_public', 'ok ret=Yes');
        Observer.Expect('set_system', 'ok ret=Yes');
        Observer.Expect('set_subset', 'ok ret=Yes');
        Observer.Expect('after_name', '[body]');
        Observer.Expect('after_public', '[pub2]');
        Observer.Expect('after_system', '[x.dtd]');
        Observer.Expect('after_subset', '[<!ELEMENT html EMPTY>]');
        Observer.Expect('after_writeto', '[<!DOCTYPE body PUBLIC "pub2" "x.dtd"[<!ELEMENT html EMPTY>]>]');
        Observer.Verify();
    end;

    [Test]
    procedure P142_Setters_On_ThreeArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('create3', Format(TryCreate3('html', 'pub', 'x.dtd')));
        Setter(Observer, 'set_name', 1, 'body');
        Setter(Observer, 'set_public', 2, 'pub2');
        Setter(Observer, 'set_system', 3, 'y.dtd');
        Setter(Observer, 'set_subset', 4, '<!ELEMENT html EMPTY>');
        AllGetters(Observer, 'after_');
        Observer.Expect('create3', 'Yes');
        Observer.Expect('set_name', 'ok ret=Yes');
        Observer.Expect('set_public', 'ok ret=Yes');
        Observer.Expect('set_system', 'ok ret=Yes');
        Observer.Expect('set_subset', 'ok ret=Yes');
        Observer.Expect('after_name', '[body]');
        Observer.Expect('after_public', '[pub2]');
        Observer.Expect('after_system', '[y.dtd]');
        Observer.Expect('after_subset', '[<!ELEMENT html EMPTY>]');
        Observer.Expect('after_writeto', '[<!DOCTYPE body PUBLIC "pub2" "y.dtd"[<!ELEMENT html EMPTY>]>]');
        Observer.Verify();
    end;

    [Test]
    procedure P142_Getters_On_NewTypes_BeforeSetters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('create1', Format(TryCreate1('html')));
        AllGetters(Observer, 'one_');
        Observer.Observe('create3', Format(TryCreate3('html', 'pub', 'x.dtd')));
        AllGetters(Observer, 'three_');
        Observer.Expect('create1', 'Yes');
        Observer.Expect('one_name', '[html]');
        Observer.Expect('one_public', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.|MemberNotInitialized');
        Observer.Expect('one_system', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.|MemberNotInitialized');
        Observer.Expect('one_subset', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.|MemberNotInitialized');
        Observer.Expect('one_writeto', '[<!DOCTYPE html >]');
        Observer.Expect('create3', 'Yes');
        Observer.Expect('three_name', '[html]');
        Observer.Expect('three_public', '[pub]');
        Observer.Expect('three_system', '[x.dtd]');
        Observer.Expect('three_subset', 'error:Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLMemberNotInitializedException'' was thrown.|MemberNotInitialized');
        Observer.Expect('three_writeto', '[<!DOCTYPE html PUBLIC "pub" "x.dtd">]');
        Observer.Verify();
    end;

    [Test]
    procedure P142_Setters_On_ThreeArguments_EmptyValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('create3', Format(TryCreate3('html', 'pub', 'x.dtd')));
        Setter(Observer, 'set_name_empty', 1, '');
        Setter(Observer, 'set_public_empty', 2, '');
        Setter(Observer, 'set_system_empty', 3, '');
        Setter(Observer, 'set_subset_empty', 4, '');
        AllGetters(Observer, 'after_');
        Observer.Expect('create3', 'Yes');
        Observer.Expect('set_name_empty', 'ok ret=No');
        Observer.Expect('set_public_empty', 'ok ret=Yes');
        Observer.Expect('set_system_empty', 'ok ret=Yes');
        Observer.Expect('set_subset_empty', 'ok ret=Yes');
        Observer.Expect('after_name', '[html]');
        Observer.Expect('after_public', '[]');
        Observer.Expect('after_system', '[]');
        Observer.Expect('after_subset', '[]');
        Observer.Expect('after_writeto', '[<!DOCTYPE html PUBLIC "" ""[]>]');
        Observer.Verify();
    end;
}
