// @expect AL0223 | The Property 'UseDefaultNamespace' can only be used if the property 'Format' is set to 'Xml'
// UseDefaultNamespace on a VariableText port: the property is for Format = Xml only (al-runner XmlPort namespace probes, writer Y83).
xmlport 52781 "MNC Y83 Use Default Ns Vt"
{
    Format = VariableText;
    Direction = Export;
    UseDefaultNamespace = true;
    schema
    {
        textelement(Root) { }
    }
}
