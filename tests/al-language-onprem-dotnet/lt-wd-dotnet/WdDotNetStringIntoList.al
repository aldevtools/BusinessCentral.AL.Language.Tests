// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 99343-99344
// Probe: written against al-runner issue 6298. The body of the System Application Uri.GetSegments: foreach over the Segments of a System.Uri into a DotNet String variable,
//        then List.Add of that variable to a List of [Text]. Also Insert, Contains, IndexOf and Set with the DotNet String, and a DotNet String added to a List of [Code[20]].
//        Every value asserted below is what the BC service tier produced.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.String"; LtWdString) { }
    }
    assembly("System")
    {
        type("System.Uri"; LtWdUriSeg) { }
    }
}

codeunit 99343 "LT WD Uri Segments"
{
    procedure GetSegments(UriText: Text; var Segments: List of [Text])
    var
        Uri: DotNet LtWdUriSeg;
        Segment: DotNet LtWdString;
        Result: List of [Text];
    begin
        Uri := Uri.Uri(UriText);
        foreach Segment in Uri.Segments do
            Result.Add(Segment);
        Segments := Result;
    end;
}

codeunit 99344 "LT WD DotNet String Into List"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Join(Items: List of [Text]): Text
    var
        Item: Text;
        Result: Text;
    begin
        foreach Item in Items do
            Result += '[' + Item + ']';
        exit(Result);
    end;

    [Test]
    procedure WD_DotNetString_ListAdd_UriSegments()
    var
        Observer: Codeunit "Probe Observer";
        UriSegments: Codeunit "LT WD Uri Segments";
        Segments: List of [Text];
    begin
        UriSegments.GetSegments('https://example.com/a/b', Segments);
        Observer.Observe('count', Format(Segments.Count()));
        Observer.Observe('items', Join(Segments));
        Observer.Expect('count', '3');
        Observer.Expect('items', '[/][a/][b]');
        Observer.Verify();
    end;

    [Test]
    procedure WD_DotNetString_ListOtherMethods()
    var
        Observer: Codeunit "Probe Observer";
        Items: List of [Text];
        Codes: List of [Code[20]];
        S: DotNet LtWdString;
    begin
        S := 'Abc';
        Items.Add('x');
        Items.Insert(1, S);
        Observer.Observe('after Insert', Join(Items));
        Observer.Observe('Contains', Format(Items.Contains(S)));
        Observer.Observe('IndexOf', Format(Items.IndexOf(S)));
        Items.Set(2, S);
        Observer.Observe('after Set', Join(Items));
        Observer.Observe('Remove', Format(Items.Remove(S)));
        Observer.Observe('after Remove', Join(Items));
        Codes.Add(S);
        Observer.Observe('code list', Format(Codes.Get(1)));
        Observer.Expect('after Insert', '[Abc][x]');
        Observer.Expect('Contains', 'Yes');
        Observer.Expect('IndexOf', '1');
        Observer.Expect('after Set', '[Abc][Abc]');
        Observer.Expect('Remove', 'Yes');
        Observer.Expect('after Remove', '[Abc]');
        Observer.Expect('code list', 'ABC');
        Observer.Verify();
    end;
}
