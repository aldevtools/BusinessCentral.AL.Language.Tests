// @expect AL0335 | Attributes must be specified before elements inside of an element.
// An xmlport text element that declares a text attribute after its child text element does not compile: attributes come first.
xmlport 50000 "MNC TP Attr Order"
{
    schema
    {
        textelement(root)
        {
            textelement(entry)
            {
                textelement(inner) { }
                textattribute(kind) { }
            }
        }
    }
}
