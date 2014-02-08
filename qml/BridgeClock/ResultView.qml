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
    visible: true
    property bool loadTarget: false

    transform: Scale {id: scaler; origin.x: 0; origin.y: 0; xScale: 1.0; yScale: 1.0}

    function getScaler() {return scaler;}
    function getHide() {return hide;}

    function log(msg) {
            var d = new Date();
            console.log(view + " " + d.getSeconds() + "." + d.getMilliseconds() + " " + msg);
    }
    function doScale() {
        var size = view.experimental.test.contentsSize;
        var y = timeView.y + timeView.height;
        var height = clockWindow.height - y;
        var width = size.width < 0 || clockWindow.width < size.width ? clockWindow.width : size.width
        var scale = 1.0
        if (width !== clockWindow.width)
            scale = clockWindow.width / width;

        var contentscale = view.experimental.test.contentsScale;
        var limitwidth = timeController.zoomLimit.width

        if (size.width > limitwidth)
            scale *= size.width/limitwidth;

        view.width = view.opacity  == 1.0 ? width : 640
        view.height = height / scale;
        view.y = y;
        view.x = 0;
        scaler.xScale = scale;
        scaler.yScale = scale;
        view.contentX = zoomLimitx();
        if (!view.loadTarget) {
            clockWindow.calculateAnimation();
        }
    }

    NumberAnimation on opacity {
        id: hide
        duration: 1000
        from: 1
        to: 0
        running: false
        onRunningChanged: {
            if (!running) {
                scaleTimeout.restart();
            }
        }
    }

    function zoomLimity() {
        return timeController.zoomLimit.y*view.experimental.test.contentsScale
    }
    function zoomLimitx() {
        return timeController.zoomLimit.x*view.experimental.test.contentsScale
    }
    function zoomLimitheight() {
        return timeController.zoomLimit.height*view.experimental.test.contentsScale
    }
    function zoomLimitwidth() {
        return timeController.zoomLimit.width*view.experimental.test.contentsScale
    }

    function reorderForSwitch() {
        var other = view == results ? resultsHidden : results;
        if (other.z <= view.z) {
            other.z = 1;
            view.z = 0;
        }

        view.opacity = 1.0
    }

    function startSwitch(other) {
        /* Is still animating previous switch ? */
        if (hide.running)
            hide.complete()
        if (!view.loadTarget) {
            /* If we were visible before start hiding animation */
            if (view.opacity == 1.0) {
                hide.start();
            }
        } else {
            /* We have to be below current results to appear smoothly durring animation */
        }
        view.loadTarget = !view.loadTarget
    }

    /* Move load target to other webview after first frame completed */
    function targetSwitch() {
            if (results.loadTarget) {
                results.startSwitch(resultsHidden);
                resultsHidden.startSwitch(results);
            } else {
                resultsHidden.startSwitch(results);
                results.startSwitch(resultsHidden);
            }
    }

    onLoadingChanged: {
        switch (loadRequest.status)
        {
        case WebView.LoadSucceededStatus:
            reorderForSwitch();
            break
        case WebView.LoadStartedStatus:
        case WebView.LoadStoppedStatus:
            break
        case WebView.LoadFailedStatus:
            log("Failed to load " + url);
            break
        }
    }

    onContentYChanged: {
        if (view.loadTartget) {
            return;
        }
        if (view.contentY == clockWindow.ypos) {
            return;
        }
        log("Fixing contentY " + view.contentY+" = "+clockWindow.ypos);
        view.contentY = clockWindow.ypos;
    }

    onHeightChanged: scaleTimeout.restart();
    onContentHeightChanged: scaleTimeout.restart();
    onWidthChanged: scaleTimeout.restart();
    onContentWidthChanged: scaleTimeout.restart();
    experimental.onLoadVisuallyCommitted: {scaleTimeout.stop(); targetSwitch(); doScale(); clockWindow.pageLoaded(view);}

    Connections {
        target: view.experimental.test
        onContentsScaleChanged: scaleTimeout.restart();
    }

    Timer {
        id: scaleTimeout
        interval: 36
        running: false
        repeat: false
        onTriggered: {
            doScale();
        }
    }

    onNavigationRequested: {
        if (request.navigationType == WebView.OtherNavigation && !view.loadTarget) {
            if (results.loadTarget)
                results.url = request.url
            else
                resultsHidden.url = request.url
        }

        if (request.navigationType != WebView.OtherNavigation || !view.loadTarget)
            request.action = WebView.IgnoreRequest;
        else
            request.action = WebView.AcceptRequest;
    }

    Component.onCompleted: {
        view.experimental.preferences.javascriptEnabled = false;
    }
}
