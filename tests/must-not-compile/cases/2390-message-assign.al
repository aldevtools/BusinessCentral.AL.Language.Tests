// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'String' of 'Message(Text, [Joker])'
// Message has a required parameter and a value list: `Message := 'x'` is checked as Message() and refused. (al-runner 7597)
codeunit 50000 "MNC C2390"
{
    procedure Run1()
    begin
        Message := 'x';
    end;
}
