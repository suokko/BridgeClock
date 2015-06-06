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

#pragma once

#include <QQuickItem>

class MouseEvent;
class GlobalMouseAreaPrivate;

class GlobalMouseArea : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(bool containsMouse READ containsMouse NOTIFY containsMouseChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool hoverEnabled READ hoverEnabled WRITE setHoverEnabled NOTIFY hoverEnabledChanged)

public:
    explicit GlobalMouseArea(QQuickItem *parent = 0);
    ~GlobalMouseArea();

    bool enabled() const;
    bool containsMouse() const;
    bool hoverEnabled() const;
    Qt::MouseButtons pressed() const;

    void setEnabled(bool);
    void setHoverEnabled(bool h);

signals:
    void enabledChanged();
    void containsMouseChanged();
    void hoverEnabledChanged();
    void pressed(MouseEvent *mouse);
    void released(MouseEvent *mouse);
    void doubleClicked(MouseEvent *mouse);
    void positionChanged(MouseEvent *mouse);

public slots:
protected:
    void setContainsMouse(bool v);
    bool setPressed(QPointF &pos, Qt::MouseButton button, bool v);
    bool sendMouseEvent(QMouseEvent *event);

    virtual void mousePressEvent(QMouseEvent *event);
    virtual void mouseReleaseEvent(QMouseEvent *event);
    virtual void mouseDoubleClickEvent(QMouseEvent *event);
    virtual void mouseMoveEvent(QMouseEvent *event);
    virtual void mouseUngrabEvent();
    virtual void hoverEnterEvent(QHoverEvent *event);
    virtual void hoverMoveEvent(QHoverEvent *event);
    virtual void hoverLeaveEvent(QHoverEvent *event);
    virtual bool childMouseEventFilter(QQuickItem *i, QEvent *e);
    virtual void windowDeactivateEvent();

    virtual void itemChange(ItemChange change, const ItemChangeData& value);
    virtual QSGNode *updatePaintNode(QSGNode *, UpdatePaintNodeData *);

private:
    void handlePress();
    void handleRelease();
    void ungrabMouse();

    class GlobalMouseAreaPrivate *d;
};
