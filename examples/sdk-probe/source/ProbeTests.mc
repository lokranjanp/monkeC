import Toybox.Lang;
import Toybox.Test;

(:test)
function missingValueIsNotZero(logger as Logger) as Boolean {
    Test.assertEqual(ProbeLogic.label(null), "--");
    Test.assertEqual(ProbeLogic.label(0), "0");
    return true;
}

(:test)
function symbolAndStringKeysDiffer(logger as Logger) as Boolean {
    var values = {:count => 7, "count" => 9};
    Test.assert(values[:count] == 7);
    Test.assert(values["count"] == 9);
    Test.assert(values["missing"] == null);
    return true;
}

(:test)
function methodKeepsItsReceiver(logger as Logger) as Boolean {
    var counter = new ProbeCounter();
    var callback = counter.method(:increment);
    callback.invoke();
    Test.assertEqual(counter.count, 1);
    return true;
}

(:test)
function integerDivisionNeedsConversion(logger as Logger) as Boolean {
    Test.assertEqual(5 / 2, 2);
    Test.assertEqual(5.toFloat() / 2, 2.5);
    return true;
}

(:test)
function typedArrayAndCapabilityGuard(logger as Logger) as Boolean {
    var values = [1, 2, 3] as Array<Number>;
    Test.assertEqual(values.size(), 3);
    var counter = new ProbeCounter();
    Test.assert(counter has :increment);
    return true;
}
