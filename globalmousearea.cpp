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
#include "globalmousearea.h"
#include "mouseevent.h"

#include <QQuickItem>
#include <QQuickWindow>

class GlobalMouseAreaPrivate {
    bool enabled_ : 1;
    bool contains_ : 1;
    bool doubleClick_: 1;
    bool stealMouse_: 1;
    Qt::MouseButtons pressed_;
    friend class GlobalMouseArea;

    GlobalMouseAreaPrivate() :
        enabled_(true),
        contains_(false),
        doubleClick_(false),
        pressed_(0)
    {}
};

GlobalMouseArea::GlobalMouseArea(QQuickItem *parent) :
    QQuickItem(parent),
    d(new GlobalMouseAreaPrivate)
{
    setAcceptedMouseButtons(Qt::LeftButton);
    setFiltersChildMouseEvents(true);
}

bool GlobalMouseArea::enabled() const
{
    return d->enabled_;
}

void GlobalMouseArea::setEnabled(bool v)
{
    if (d->enabled_ != v) {
        d->enabled_ = v;
        emit enabledChanged();
    }
}

Qt::MouseButtons GlobalMouseArea::pressed() const
{
    return d->pressed_;
}

bool GlobalMouseArea::setPressed(QPointF &pos, Qt::MouseButton button, bool v)
{
    bool old = d->pressed_ & button;
    if (old != v) {
        if (v) {
            d->pressed_ |= button;
        } else {
            d->pressed_ &= ~button;
        }
        MouseEvent e(pos.rx(), pos.ry(), d->pressed_);
        if (v) {
            emit pressed(&e);
        } else {
            emit released(&e);
        }

        return true;
    }
    return false;
}

void GlobalMouseArea::setContainsMouse(bool v)
{
    if (d->contains_ != v) {
        d->contains_ = v;
        emit containsMouseChanged();
    }
}

bool GlobalMouseArea::containsMouse() const
{
    return d->contains_;
}

void GlobalMouseArea::setHoverEnabled(bool h)
{
    if (h != acceptHoverEvents()) {
        setAcceptHoverEvents(h);
        emit hoverEnabledChanged();
    }
}

bool GlobalMouseArea::hoverEnabled() const
{
    return acceptHoverEvents();
}

void GlobalMouseArea::ungrabMouse()
{
    if (d->pressed_) {
        d->pressed_ = 0;
        d->stealMouse_ = false;
        setKeepMouseGrab(false);

        if (d->contains_ && !isUnderMouse()) {
            d->contains_ = false;
            emit containsMouseChanged();
        }
    }
}

void GlobalMouseArea::mouseMoveEvent(QMouseEvent *event)
{
    if (!enabled() && !pressed()) {
        QQuickItem::mouseMoveEvent(event);
        return;
    }

    QPointF sp = event->screenPos();
    MouseEvent e(sp.rx(), sp.ry(), event->buttons());
    emit positionChanged(&e);
}

void GlobalMouseArea::hoverEnterEvent(QHoverEvent *event)
{
    if (!enabled() && !pressed()) {
        QQuickItem::hoverEnterEvent(event);
        return;
    }
    setContainsMouse(true);
}

void GlobalMouseArea::hoverLeaveEvent(QHoverEvent *event)
{
    if (!enabled() && !pressed()) {
        QQuickItem::hoverLeaveEvent(event);
        return;
    }
    setContainsMouse(false);
}

void GlobalMouseArea::hoverMoveEvent(QHoverEvent *event)
{
    if (!d->enabled_ && !d->pressed_) {
        QQuickItem::hoverMoveEvent(event);
        return;
    }
    QPointF pos = event->posF();
    MouseEvent e(pos.rx(), pos.ry(), d->pressed_);
    emit positionChanged(&e);
}

void GlobalMouseArea::mousePressEvent(QMouseEvent *event)
{
    if (!d->enabled_ && !d->pressed_) {
        QQuickItem::mouseReleaseEvent(event);
        return;
    }
    setContainsMouse(true);
    setKeepMouseGrab(true);
    QPointF pos = event->screenPos();
    event->setAccepted(setPressed(pos, event->button(), true));
}

void GlobalMouseArea::mouseReleaseEvent(QMouseEvent *event)
{
    d->stealMouse_ = false;
    if (!d->enabled_ && !d->pressed_) {
        QQuickItem::mouseReleaseEvent(event);
    } else {
        QPointF pos = event->screenPos();
        setPressed(pos, event->button(), false);
        if (!d->pressed_) {
            if (!acceptHoverEvents())
                setContainsMouse(false);
            QQuickWindow *w = window();
            if (w && w->mouseGrabberItem() == this)
                ungrabMouse();
            setKeepMouseGrab(false);
        }
    }
    d->doubleClick_ = false;
}

void GlobalMouseArea::mouseUngrabEvent()
{
    ungrabMouse();
}

void GlobalMouseArea::windowDeactivateEvent()
{
    ungrabMouse();
    QQuickItem::windowDeactivateEvent();
}

void GlobalMouseArea::mouseDoubleClickEvent(QMouseEvent *event)
{
    if (!d->enabled_ && !d->pressed_) {
        QQuickItem::mouseDoubleClickEvent(event);
        return;
    }
    d->doubleClick_ = true;
    QPointF pos = event->screenPos();
    MouseEvent e(pos.rx(), pos.ry(), d->pressed_);
    emit doubleClicked(&e);
}

bool GlobalMouseArea::childMouseEventFilter(QQuickItem *i, QEvent *e)
{
    if (!d->pressed_ &&
            (!d->enabled_ || !isVisible())
       )
        return QQuickItem::childMouseEventFilter(i, e);
    switch (e->type()) {
    case QEvent::MouseButtonPress:
    case QEvent::MouseMove:
    case QEvent::MouseButtonRelease:
        return sendMouseEvent(static_cast<QMouseEvent *>(e));
    default:
        break;
    }

    return QQuickItem::childMouseEventFilter(i, e);
}

bool GlobalMouseArea::sendMouseEvent(QMouseEvent *event)
{
    QPointF localPos = mapFromScene(event->windowPos());

    QQuickWindow *c = window();
    QQuickItem *grabber = c ? c->mouseGrabberItem() : 0;
    if ((contains(localPos)) && (!grabber || !grabber->keepMouseGrab())) {
        QMouseEvent mouseEvent(event->type(), localPos, event->windowPos(), event->screenPos(),
                               event->button(), event->buttons(), event->modifiers());
        mouseEvent.setAccepted(false);

        switch (event->type()) {
        case QEvent::MouseMove:
            mouseMoveEvent(&mouseEvent);
            break;
        case QEvent::MouseButtonPress:
            mousePressEvent(&mouseEvent);
            break;
        case QEvent::MouseButtonRelease:
            mouseReleaseEvent(&mouseEvent);
            break;
        default:
            break;
        }

        return false;
    }
    if (event->type() == QEvent::MouseButtonRelease) {
        if (d->pressed_) {
            d->pressed_ &= ~event->button();
            if (!d->pressed_) {
                // no other buttons are pressed
                d->stealMouse_ = false;
                if (c && c->mouseGrabberItem() == this)
                    ungrabMouse();
                if (d->contains_) {
                    d->contains_ = false;
                    emit containsMouseChanged();
                }
            }
        }
    }
    return false;
}

void GlobalMouseArea::itemChange(ItemChange change, const ItemChangeData &value)
{
    switch (change) {
    case ItemVisibleHasChanged:
        if (acceptHoverEvents() && d->contains_ != (isVisible() && isUnderMouse())) {
            setContainsMouse(!d->contains_);
        }
        break;
    default:
        break;
    }

    QQuickItem::itemChange(change, value);
}

QSGNode *GlobalMouseArea::updatePaintNode(QSGNode *, UpdatePaintNodeData *)
{
    return 0;
}
