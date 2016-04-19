// Expectation for test: 
// main() {
//   var x = 122;
//   var a = () {
//     var y = x;
//     return () => y;
//   };
//   x = x + 1;
//   print(a()());
// }

function() {
  var line = H.S(122 + 1);
  if (typeof dartPrint == "function")
    dartPrint(line);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(line);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(line);
    print(line);
  }
}
