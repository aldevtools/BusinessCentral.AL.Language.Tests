// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

xmlport 72155 "LT P121 XP MaxOcc"
{
    Direction = Import;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(RowEl; "LT P121 Row")
            {
                fieldelement(Id; RowEl.Id) { }
                fieldelement(Txt; RowEl.Txt)
                {
                    MinOccurs = Zero;
                    MaxOccurs = Once;
                }
                fieldelement(Qty; RowEl.Qty)
                {
                    MinOccurs = Once;
                    MaxOccurs = Unbounded;
                }
            }
        }
    }

}

codeunit 72156 "LT P121 XP MaxOcc Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_Import()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        Helper.ImportText(Xmlport::"LT P121 XP MaxOcc", '<Root><RowEl><Id>41</Id><Txt>a</Txt><Qty>1</Qty></RowEl></Root>');
        Observer.Observe('rows_single', Helper.Rows());
        Helper.Seed();
        Helper.ImportText(Xmlport::"LT P121 XP MaxOcc", '<Root><RowEl><Id>42</Id><Qty>2</Qty></RowEl></Root>');
        Observer.Observe('rows_no_txt', Helper.Rows());
        Helper.Seed();
        asserterror Helper.ImportText(Xmlport::"LT P121 XP MaxOcc", '<Root><RowEl><Id>43</Id><Txt>a</Txt><Txt>b</Txt><Qty>3</Qty></RowEl></Root>');
        Observer.ObserveError('two_txt');
        Observer.Observe('rows_after_two_txt', Helper.Rows());
        Helper.Seed();
        asserterror Helper.ImportText(Xmlport::"LT P121 XP MaxOcc", '<Root><RowEl><Id>44</Id><Txt>a</Txt></RowEl></Root>');
        Observer.ObserveError('no_qty');
        Observer.Observe('rows_after_no_qty', Helper.Rows());
        Helper.Seed();
        Helper.ImportText(Xmlport::"LT P121 XP MaxOcc", '<Root><RowEl><Id>45</Id><Qty>1</Qty><Qty>2</Qty></RowEl></Root>');
        Observer.Observe('rows_two_qty', Helper.Rows());
        Observer.Expect('rows_single', '1:a:10,2:b:20,41:a:1,');
        Observer.Expect('rows_no_txt', '1:a:10,2:b:20,42::2,');
        Observer.Expect('two_txt|text', 'Imported XML cannot validate with the schema: The element ''RowEl'' has invalid child element ''Txt''. List of possible elements expected: ''Qty''.');
        Observer.Expect('two_txt|code', 'XmlPortInvalidXml');
        Observer.Expect('rows_after_two_txt', '');
        Observer.Expect('no_qty|text', 'Imported XML cannot validate with the schema: The element ''RowEl'' has incomplete content. List of possible elements expected: ''Qty''.');
        Observer.Expect('no_qty|code', 'XmlPortInvalidXml');
        Observer.Expect('rows_after_no_qty', '');
        Observer.Expect('rows_two_qty', '1:a:10,2:b:20,45::2,');
        Observer.Verify();
    end;

}
