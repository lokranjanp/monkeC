import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ProbeApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        System.println("SDK probe started");
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new ProbeView()];
    }
}

class ProbeView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2,
            Graphics.FONT_SMALL, "Monkey C works",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

module ProbeLogic {
    function label(value as Number?) as String {
        if (value == null) {
            return "--";
        }
        return value.format("%d");
    }
}

class ProbeCounter {
    var count as Number = 0;

    function initialize() {
    }

    function increment() as Void {
        count += 1;
    }
}
