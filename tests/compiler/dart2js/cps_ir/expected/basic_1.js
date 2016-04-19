// Expectation for test: 
// main() {
//   var e = 1;
//   var l = [1, 2, 3];
//   var m = {'s': 1};
// 
//   print('(' ')');
//   print('(${true})');
//   print('(${1})');
//   print('(${[1, 2, 3]})');
//   print('(${{'s': 1}})');
//   print('($e)');
//   print('($l)');
//   print('($m)');
// }

function() {
  var l = [1, 2, 3], m = P.LinkedHashMap__makeLiteral(["s", 1]);
  P.print("()");
  P.print("(true)");
  P.print("(1)");
  P.print("(" + H.S([1, 2, 3]) + ")");
  P.print("(" + P.Maps_mapToString(P.LinkedHashMap__makeLiteral(["s", 1])) + ")");
  P.print("(1)");
  P.print("(" + H.S(l) + ")");
  P.print("(" + P.Maps_mapToString(m) + ")");
}
