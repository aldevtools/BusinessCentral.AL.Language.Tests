// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Char'. Use an explicit conversion or change the type.
// currXMLport.FieldSeparator read back is a Text: it does not convert to a Char (writer Y67, gap cycle 6 follow-up).
table 52654 "MNC Y67 Back Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

xmlport 52655 "MNC Y67 Back Char"
{
    Format = VariableText;
    Direction = Export;
    schema
    {
        textelement(Root)
        {
            tableelement(R; "MNC Y67 Back Row")
            {
                fieldelement(Id; R.Id) { }
            }
        }
    }

    trigger OnPreXmlPort()
    var
        C: Char;
    begin
        C := currXMLport.FieldSeparator;
    end;
}
