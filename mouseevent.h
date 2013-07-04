#ifndef MOUSEEVENT_H
#define MOUSEEVENT_H

#include <QObject>

class MouseEvent : public QObject
{
    Q_OBJECT

    Q_PROPERTY(qreal x READ x)
    Q_PROPERTY(qreal y READ y)
    Q_PROPERTY(int buttons READ buttons)
public:
    explicit MouseEvent(const qreal &x = 0, const qreal &y = 0, int buttons = 0);

    qreal x() const;
    qreal y() const;
    int buttons() const;

signals:

public slots:

private:
    qreal x_;
    qreal y_;
    int buttons_;
};

#endif // MOUSEEVENT_H
