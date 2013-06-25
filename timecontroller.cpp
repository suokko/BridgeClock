#include "timecontroller.h"

#include "timemodel.h"
#include "roundinfo.h"

#include <QDateTime>
#include <QTimer>

#include <QFileSystemWatcher>

#include <QDebug>

#include <QCursor>
#include <QQuickItem>
#include <QQuickWindow>

class TimeControllerPrivate {
    QString resultUrl_;
    QTimer *urlTimer_;
    QFileSystemWatcher *watcher_;
    TimeModel *model_;
    QRect origWindow;
    QPoint resizePoint;
    friend class TimeController;
};

TimeController::TimeController() :
    QObject(),
    d(new TimeControllerPrivate)
{
    d->urlTimer_ = NULL;
    d->watcher_ = NULL,
    d->model_ = new TimeModel();
}

TimeController::~TimeController()
{
    delete d->model_;
}

unsigned TimeController::rounds() const
{
    return d->model_->rounds();
}

unsigned TimeController::roundTime() const
{
    return d->model_->roundTime();
}

unsigned TimeController::roundBreak() const
{
    return d->model_->roundBreak();
}

const QDateTime & TimeController::startTime() const
{
    return d->model_->startTime();
}

void TimeController::setRounds(unsigned v)
{
    d->model_->setRounds(v);
}

void TimeController::setRoundTime(unsigned v)
{
    d->model_->setRoundTime(v);
}

void TimeController::setRoundBreak(unsigned v)
{
    d->model_->setRoundBreak(v);
}

void TimeController::setStartTime(const QDateTime & v)
{
    d->model_->setStartTime(v);
}

RoundInfo *TimeController::getRoundInfo() const
{
    const TimeItem *item = d->model_->getCurrent();
    QDateTime end(QDateTime::currentDateTime());
    QString nextName = "";
    QString name = item[0].name_;
    int playing = item[0].type_ == TimeItem::Play ? 1 : 0;


    if (item[0].type_ != TimeItem::End) {
        if (item[0].start_ < end) {
            int next = 1;
            while (item[next].type_ == TimeItem::Change)
                next++;
            end = item[1].start_;
            nextName = item[next].name_;
        } else {
            end = item[0].start_;
            nextName = item[0].name_;
            name = "Kilpailun alkuun";
        }
    } else {
        playing = 2;
    }
    return new RoundInfo(end.toTime_t(), name, nextName, playing);
}

TimeModel * TimeController::getModel()
{
    return d->model_;
}

void TimeController::setItemCursor(QQuickItem *obj, const QString &cursor)
{
    if (!obj) {
        qWarning("Setting cursor for null object");
        return;
    }

    if (cursor == "") {
        obj->unsetCursor();
        return;
    }

    Qt::CursorShape shape = Qt::ArrowCursor;
    if (cursor == "move")
        shape = Qt::SizeAllCursor;
    else if (cursor == "T" || cursor == "B")
        shape = Qt::SizeVerCursor;
    else if (cursor == "L" || cursor == "R")
        shape = Qt::SizeHorCursor;
    else if (cursor == "TR" || cursor == "BL")
        shape = Qt::SizeBDiagCursor;
    else if (cursor == "TL" || cursor == "BR")
        shape = Qt::SizeFDiagCursor;
    obj->setCursor(QCursor(shape));
}

const QString &TimeController::resultUrl() const
{
    return d->resultUrl_;
}

#include <QDir>
#include <QFileInfo>

void TimeController::urlUpdate()
{
    delete d->urlTimer_;
    d->urlTimer_ = NULL;
    delete d->watcher_;
    d->watcher_ = NULL;
    if (d->resultUrl_.startsWith("file://")) {
        QFileInfo path = d->resultUrl_.right(d->resultUrl_.size() - 7);
        d->watcher_ = new QFileSystemWatcher(this);
//        watcher_->addPath(path.absolutePath());
        d->watcher_->addPath(path.absoluteFilePath());
        connect(d->watcher_, SIGNAL(fileChanged(QString)), SLOT(fileChanged(QString)));
        connect(d->watcher_, SIGNAL(directoryChanged(QString)), SLOT(fileChanged(QString)));
    }
    emit updateResults(d->resultUrl_);
}

void TimeController::fileChanged(const QString &path)
{
    QFileInfo info(path);
    if (!info.exists()) {
        qDebug() << "Not existing";
        d->watcher_->addPath(info.absolutePath());
        d->watcher_->removePath(info.absoluteFilePath());
        return;
    }
    if (info.isDir()) {
        QFileInfo cur = d->resultUrl_.right(d->resultUrl_.size() - 7);
        if (!cur.exists()) {
            qDebug() << "File not existing";
            return;
        }
        if (cur.absoluteDir() == info.absoluteFilePath()) {
            qDebug() << "Add file back to watch list";
            d->watcher_->addPath(cur.absoluteFilePath());
            d->watcher_->removePath(cur.absolutePath());
        }
    }
    emit updateResults(d->resultUrl_);
}

void TimeController::setResultUrl(const QString &url)
{
    d->resultUrl_ = url;
    if (d->urlTimer_)
        d->urlTimer_->stop();
    delete d->urlTimer_;
    d->urlTimer_ = new QTimer(this);
    d->urlTimer_->setSingleShot(true);
    d->urlTimer_->setInterval(2000);
    connect(d->urlTimer_, SIGNAL(timeout()), SLOT(urlUpdate()));
    d->urlTimer_->start();
}

void TimeController::moveWindow(QQuickWindow *w, int dx, int dy)
{
    if (!w) {
        qWarning("Window object missing");
        return;
    }
    QPoint p = w->mapToGlobal(QPoint(dx,dy));
    QRect rect = w->geometry();
    rect.translate(p.rx() - rect.x(), p.ry() - rect.y());
    w->setGeometry(rect);
}

void TimeController::startResize(QQuickWindow *w, QQuickItem *obj, int x, int y)
{
    if (!w) {
        qWarning("Window object missing");
        return;
    }

    if (!obj) {
        qWarning("QML object missing");
        return;
    }
    d->origWindow = w->geometry();
    QPointF pf(x, y);
    pf = obj->mapToItem(NULL, pf);
    d->resizePoint = w->mapToGlobal(QPoint(pf.rx(), pf.ry()));
}

void TimeController::resizeWindow(QQuickWindow *w, QQuickItem *obj, int dx, int dy, const QString &top)
{
    if (!w) {
        qWarning("Window object missing");
        return;
    }

    if (!obj) {
        qWarning("QML object missing");
        return;
    }
    QPointF pf(dx, dy);
    pf = obj->mapToItem(NULL, pf);
    QPoint p = w->mapToGlobal(QPoint(pf.rx(),pf.ry()));
    p -= d->resizePoint;
    QRect newSize = d->origWindow;

    if (top == "T")
        newSize.adjust(0, p.ry(), 0, 0);
    else if (top == "B")
        newSize.adjust(0, 0, 0, p.ry());
    else if (top == "L")
        newSize.adjust(p.rx(), 0, 0, 0);
    else if (top == "R")
        newSize.adjust(0, 0, p.rx(), 0);
    else if (top == "TR")
        newSize.adjust(0, p.ry(), p.rx(), 0);
    else if (top == "BR")
        newSize.adjust(0, 0, p.rx(), p.ry());
    else if (top == "TL")
        newSize.adjust(p.rx(), p.ry(), 0, 0);
    else if (top == "BL")
        newSize.adjust(p.rx(), 0, 0, p.ry());

    w->setGeometry(newSize);
}

