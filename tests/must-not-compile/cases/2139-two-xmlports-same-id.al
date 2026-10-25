// @expect AL0264 | An application object of type 'XmlPort' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'XmlPort' with ID '50001' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two xmlports with the same id (the type is spelled 'XmlPort').
xmlport 50001 "MNC SH Xmlport A"
{
    schema
    {
        textelement(Root)
        {
        }
    }
}

xmlport 50001 "MNC SH Xmlport B"
{
    schema
    {
        textelement(Root)
        {
        }
    }
}
