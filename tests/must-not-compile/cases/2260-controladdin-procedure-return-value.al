// @expect AL0416 | Method 'Ask' cannot have a return value.
// A control add-in procedure cannot declare a return value (the call goes to the client and returns nothing to AL; an answer comes back as an
// add-in event). Runtime test for procedures without a return value: tests/al-language/lt-ac/ACControlAddIn.al (TZ tests).
controladdin "MNC TZ Addin 2260"
{
    RequestedHeight = 50;
    RequestedWidth = 50;

    procedure Say(Message: Text);
    procedure Ask(Question: Text): Text;
}
