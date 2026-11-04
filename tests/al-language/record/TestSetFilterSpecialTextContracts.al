// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-filter-expressions
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 68980, codeunit 68981
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins SetFilter(Field, '%1', Text) with a text that holds filter characters, on a Text field holding John@Example.com,
// a&b@x.com, a|b, a(b), a<b, a=b, a'b, a..b, a*b and axb:
//  - the value is taken as TEXT, not as a filter, except that * and ? stay wildcards ("a*b" matches the seven values that start
//    with a and end with b) and a leading @ makes the match ignore case ('@john@example.com' finds John@Example.com);
//  - & | ( ) < = and .. in the value make BC quote the whole value in GetFilter: 'a&b@x.com', 'a|b', 'a(b)', 'a<b', 'a=b',
//    'a..b' (and '@a|b' with the @ inside the quotes); the quoted filter finds exactly that value (count 1);
//  - an apostrophe, @ and plain text are not quoted: a'b, John@Example.com, axb, @axb.
// BC versions: 27.5

codeunit 68981 "Probe SetFilter Special Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        SfRec: Record "ALT Shape 18";
        Values: List of [Text];
        Value: Text;
        Index: Integer;
    begin
        SfRec.DeleteAll();
        Values.Add('John@Example.com');
        Values.Add('a&b@x.com');
        Values.Add('a|b');
        Values.Add('a(b)');
        Values.Add('a<b');
        Values.Add('a=b');
        Values.Add('a''b');
        Values.Add('a..b');
        Values.Add('a*b');
        Values.Add('axb');
        foreach Value in Values do begin
            Index += 1;
            SfRec.Id := Index;
            SfRec.Name := CopyStr(Value, 1, MaxStrLen(SfRec.Name));
            SfRec.Insert();
        end;
    end;

    local procedure Matches(Value: Text; ExpectedCount: Integer; ExpectedFilter: Text)
    var
        SfRec: Record "ALT Shape 18";
    begin
        SfRec.SetFilter(Name, '%1', Value);
        Assert.AreEqual(ExpectedCount, SfRec.Count(), 'count of ' + Value);
        Assert.AreEqual(ExpectedFilter, SfRec.GetFilter(Name), 'GetFilter of ' + Value);
    end;

    [Test]
    procedure PlainTextAndWildcards()
    begin
        Seed();

        Matches('John@Example.com', 1, 'John@Example.com');
        Matches('@john@example.com', 1, '@john@example.com');
        Matches('axb', 1, 'axb');
        Matches('@axb', 1, '@axb');
        Matches('a*b', 7, 'a*b');
        Matches('@A*B', 7, '@A*B');
        Matches('a''b', 1, 'a''b');
        Matches('@a''b', 1, '@a''b');
    end;

    [Test]
    procedure FilterCharacters_AreQuotedInGetFilter_AndMatchOnlyThatText()
    begin
        Seed();

        Matches('a&b@x.com', 1, '''a&b@x.com''');
        Matches('a|b', 1, '''a|b''');
        Matches('a(b)', 1, '''a(b)''');
        Matches('a<b', 1, '''a<b''');
        Matches('a=b', 1, '''a=b''');
        Matches('a..b', 1, '''a..b''');

        Matches('@a&b@x.com', 1, '''@a&b@x.com''');
        Matches('@a|b', 1, '''@a|b''');
        Matches('@a(b)', 1, '''@a(b)''');
        Matches('@a<b', 1, '''@a<b''');
        Matches('@a=b', 1, '''@a=b''');
        Matches('@a..b', 1, '''@a..b''');
    end;
}
