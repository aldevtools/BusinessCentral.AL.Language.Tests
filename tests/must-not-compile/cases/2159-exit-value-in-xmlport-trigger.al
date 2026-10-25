// @expect AL0139 | Since 'OnPreXmlPort' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnPreXmlPort trigger of an xmlport.
xmlport 50001 "MNC SH Xmlport"
{
    schema
    {
        textelement(Root)
        {
        }
    }

    trigger OnPreXmlPort()
    begin
        exit(1);
    end;
}
