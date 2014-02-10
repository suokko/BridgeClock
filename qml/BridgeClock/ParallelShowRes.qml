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

ParallelAnimation {
    NumberAnimation { target: timeView; properties: "height"; duration: transduration; easing.type: transtype }
    AnchorAnimation { targets: [current,end,nextHeading,next]; duration: transduration; easing.type: transtype }
    PropertyAnimation { target: current; properties: "font.pixelSize,anchors.leftMargin,anchors.topMargin"; duration: transduration; easing.type: transtype }
    PropertyAnimation { target: currentScale; properties: "xScale"; duration: transduration; easing.type: transtype }
    PropertyAnimation { target: endHeading; properties: "font.pixelSize"; duration: transduration; easing.type: transtype }
    PropertyAnimation { target: end; properties: "font.pixelSize"; duration: transduration; easing.type: transtype }
    PropertyAnimation { target: time; properties: "font.pixelSize"; duration: transduration; easing.type: transtype }
    PropertyAnimation { target: timeScale; properties: "xScale"; duration: transduration; easing.type: transtype }
    PropertyAnimation { target: nextHeading; properties: "font.pixelSize,anchors.bottomMargin,anchors.leftMargin,anchors.topMargin,anchors.rightMargin"; duration: transduration; easing.type: transtype}
    PropertyAnimation { target: next; properties: "font.pixelSize,anchors.topMargin"; duration: transduration; easing.type: transtype}
    PropertyAnimation { target: nextBreakEnd; properties: "font.pixelSize"; duration: transduration; easing.type: transtype}
}

