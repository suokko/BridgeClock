/*
Copyright (c) 2013 Pauli Nieminen <suokkos@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
import QtQuick 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0

WebView {
    id: view
    clip: true
    pixelAligned: false
    interactive: false
    opacity: 0.0
    visible: false
    property bool loadTarget: false
    property double ypos: -1

    transform: Scale {id: scaler; origin.x: 0; origin.y: 0; xScale: 1.0; yScale: 1.0}

    function doScale() {
        var size = view.experimental.test.contentsSize;
        var y = timeView.y + timeView.height;
        var height = clockWindow.height - y;
        var width = size.width < 0 || clockWindow.width < size.width ? clockWindow.width : size.width
        var scale = 1.0
        if (width !== clockWindow.width)
            scale = clockWindow.width / width;

        view.width = view.visible ? width : 640
        view.height = height / scale;
        view.y = y;
        view.x = 0;
        scaler.xScale = scale;
        scaler.yScale = scale;
    }

    function doAnimation() {
        if (view.url == "")
            return;
        if (!scrollTimer.running && !scroller.running) {
            scrollTimer.running = true;
            return;
        }

        if (scrollTimer.running) {
            return;
        }

        if (!clockWindow.animationDown) {
            if (!scroller.running) {
                scrollTimer.start();
            }
            return;
        }

        scroller.stop()
        var duration = (view.contentHeight - view.height - view.contentY) /
                scaler.xScale * clockWindow.scrollSpeed
        if (duration < 0) {
            duration = 0;
        }
        var scale = view.experimental.test.contentsScale
        scroller.duration = duration / scale

        if (scroller.duration == 0)
            scroller.duration = 200;

        scroller.to = view.contentHeight - view.height
        scroller.from = view.contentY;
        scrollTimer.stop()
        clockWindow.animationDown = true;
        scroller.start()
    }

    onContentYChanged: {

        if (contentY == 0 && !view.loadTarget && ypos > 0) {
            contentY = ypos;
            ypos = -1;
        }
    }

    function animationSwitch() {
        if (clockWindow.animationDown) {
            if (view.contentHeight <= view.height)
                return;
            var scale = view.experimental.test.contentsScale
            scroller.duration = (view.contentHeight - view.height) /
                    scaler.xScale * clockWindow.scrollSpeed / scale
            scroller.to = view.contentHeight - view.height
            scroller.from = 0;
            if (scroller.duration == 0)
                scroller.duration = 200;
        } else {
            if (view.contentY === 0) {
                clockWindow.animationDown = true;
                return;
            }
            scroller.duration = 200;
            scroller.to = 0;
            scroller.from = view.contentY
        }
        scroller.start();
    }

    NumberAnimation on opacity {
        id: hide
        duration: 1000
        from: 1
        to: 0
        onRunningChanged: {
            if (!running) {
                view.visible = false;
                scroller.stop();
                view.doScale();
            }
        }
    }

    function getScroller()
    {
        return scroller;
    }

    function startSwitch(other) {
        if (hide.running)
            hide.complete()
        if (!view.loadTarget) {
            if (view.visible) {
                hide.start();
            }
        } else {
            var s = other.getScroller();
            scroller.from = s.from;
            scroller.to = s.to;
            scroller.duration = s.duration;
            scroller.running = s.running;
            if (other.z <= view.z) {
                other.z = 1;
                view.z = 0;
            }

            view.visible = true;
            view.opacity = 1.0
        }
        view.loadTarget = !view.loadTarget
    }

    onLoadingChanged: {
        switch (loadRequest.status)
        {
        case WebView.LoadSucceededStatus:
            if (results.loadTarget)
                ypos = resultsHidden.contentY
            else
                ypos = results.contentY
            results.startSwitch(resultsHidden);
            resultsHidden.startSwitch(results);
            doScale();
            if (ypos !== undefined) {
                view.contentY = ypos;
                if (!scrollTimer.running)
                    ypos = -1;
            }
            doAnimation();
            break
        case WebView.LoadStartedStatus:
        case WebView.LoadStoppedStatus:
            break
        case WebView.LoadFailedStatus:
            console.log("Failed to load " + url);
            break
        }
    }

    onHeightChanged: doAnimation();
    onContentHeightChanged: doAnimation();

    onNavigationRequested: {
        if (request.navigationType != WebView.OtherNavigation)
            request.action = WebView.IgnoreRequest;
        else
            request.action = WebView.AcceptRequest;
    }

    Component.onCompleted: {
        view.experimental.preferences.javascriptEnabled = false;
        view.doScale()
    }

    NumberAnimation on contentY {
        id: scroller
        running: false
        easing.type: Easing.Linear
        onRunningChanged: {
            if (!running && !view.loadTarget) {
                scrollTimer.running = true;
                clockWindow.animationDown = !clockWindow.animationDown;
            }
        }
    }
}
