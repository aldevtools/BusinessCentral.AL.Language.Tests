// @expect AL1043 | The runtime version '0.0' is not supported by the AL compiler.
// @appjson {"runtime": "0.0"}
// app.json "runtime": "0.0" is rejected (al-runner issue 5506, writer Y10). Recorded with AL 30.0.43.45776-beta.
codeunit 50000 "MNC Codeunit"
{
}
