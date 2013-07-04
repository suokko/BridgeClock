#include "mouseevent.h"

MouseEvent::MouseEvent(const qreal &x, const qreal &y, int buttons) :
    x_(x),
    y_(y),
    buttons_(buttons)
{
}

qreal MouseEvent::x() const
{
    return x_;
}

qreal MouseEvent::y() const
{
    return y_;
}

int MouseEvent::buttons() const
{
    return buttons_;
}
