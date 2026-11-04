// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/companyproperty/companyproperty-id-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CompanyProperty.ID(): whether it answers, whether it is the null Guid, its text length, that two calls agree, its type (Guid); never the value itself (it differs per company).
// BC versions: 29 (27 and 28 by CI)

codeunit 71930 "LT P160 Company ID"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryId(var Id: Guid)
    begin
        Id := CompanyProperty.ID();
    end;

    [TryFunction]
    local procedure TryUrlName(var Name: Text)
    begin
        Name := CompanyProperty.UrlName();
    end;

    [Test]
    procedure ID_AnswersAGuid()
    var
        Observer: Codeunit "Probe Observer";
        First: Guid;
        Second: Guid;
    begin
        Observer.Observe('first call answers', Format(TryId(First)));
        Observer.ObserveError('first call');
        Observer.Observe('is null guid', Format(IsNullGuid(First)));
        Observer.Observe('text length', Format(StrLen(Format(First))));
        Observer.Observe('second call answers', Format(TryId(Second)));
        Observer.Observe('both calls agree', Format(First = Second));
        Observer.Expect('first call answers', 'Yes');
        Observer.Expect('first call|text', '');
        Observer.Expect('first call|code', '');
        Observer.Expect('is null guid', 'No');
        Observer.Expect('text length', '38');
        Observer.Expect('second call answers', 'Yes');
        Observer.Expect('both calls agree', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ID_AsText_FormatForms()
    var
        Observer: Codeunit "Probe Observer";
        Id: Guid;
    begin
        if not TryId(Id) then begin
            Observer.ObserveError('id');
            Observer.Expect('default format length', '38');
            Observer.Expect('format 9 length', '38');
            Observer.Expect('default starts with brace', 'Yes');
            Observer.Expect('format 9 lower case', 'No');
            Observer.Verify();
            exit;
        end;
        Observer.Observe('default format length', Format(StrLen(Format(Id))));
        Observer.Observe('format 9 length', Format(StrLen(Format(Id, 0, 9))));
        Observer.Observe('default starts with brace', Format(CopyStr(Format(Id), 1, 1) = '{'));
        Observer.Observe('format 9 lower case', Format(Format(Id, 0, 9) = LowerCase(Format(Id, 0, 9))));
        Observer.Expect('default format length', '38');
        Observer.Expect('format 9 length', '38');
        Observer.Expect('default starts with brace', 'Yes');
        Observer.Expect('format 9 lower case', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure UrlName_IsTheCompanyNameWithEncodedSpaces()
    var
        Observer: Codeunit "Probe Observer";
        Url: Text;
    begin
        Observer.Observe('answers', Format(TryUrlName(Url)));
        Observer.Observe('equals CompanyName', Format(Url = CompanyName()));
        Observer.Observe('equals CompanyName with spaces encoded', Format(Url = CompanyName().Replace(' ', '%20')));
        Observer.Observe('contains a blank', Format(StrPos(Url, ' ') > 0));
        Observer.Expect('answers', 'Yes');
        Observer.Expect('equals CompanyName', 'No');
        Observer.Expect('equals CompanyName with spaces encoded', 'Yes');
        Observer.Expect('contains a blank', 'No');
        Observer.Verify();
    end;
}
