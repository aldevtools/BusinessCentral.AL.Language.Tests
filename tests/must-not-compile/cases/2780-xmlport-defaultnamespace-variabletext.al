// @expect AL0223 | The Property 'DefaultNamespace' can only be used if the property 'Format' is set to 'Xml'
// DefaultNamespace on a VariableText port (and, by the same rule, on a FixedText port): the property is for Format = Xml only (al-runner XmlPort namespace probes, writer Y83).
xmlport 52780 "MNC Y83 Default Ns Vt"
{
    Format = VariableText;
    Direction = Export;
    DefaultNamespace = 'urn:y83';
    schema
    {
        textelement(Root) { }
    }
}
