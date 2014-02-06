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
    bool showResults_ : 1;
    bool paused_ : 1;
    QString resultUrl_;
    QTimer *urlTimer_;
    QFileSystemWatcher *watcher_;
    TimeModel *model_;
    QRect origWindow;
    QPoint resizePoint;
    RoundInfo *roundInfo_;
    QRect zoomLimit_;
    friend class TimeController;
};

TimeController::TimeController() :
    QObject(),
    d(new TimeControllerPrivate)
{
    d->showResults_ = false;
    d->paused_ = false;
    d->urlTimer_ = new QTimer(this);
    d->urlTimer_->setSingleShot(true);
    connect(d->urlTimer_, SIGNAL(timeout()), SLOT(urlUpdate()));
    d->watcher_ = NULL,
    d->model_ = new TimeModel();
    d->roundInfo_ = NULL;

    connect(d->model_, SIGNAL(dataChanged(QModelIndex,QModelIndex)), SIGNAL(tournamentEndChanged()));
}

TimeController::~TimeController()
{
    delete d->model_;
    delete d->urlTimer_;
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

bool TimeController::showResults() const
{
    return d->showResults_;
}

void TimeController::setShowResults(bool v)
{
    if (v == d->showResults_)
        return;
    d->showResults_ = v;
    emit showResultsChanged();
}

QRect TimeController::getZoomLimit() const
{
    return d->zoomLimit_;
}

void TimeController::setZoomLimit(QRect &v)
{
    if (v == d->zoomLimit_)
        return;
    d->zoomLimit_ = v;
    emit zoomLimitChanged();
}

bool TimeController::paused() const
{
    return d->paused_;
}

void TimeController::setPaused(bool v)
{
    if (v == d->paused_)
        return;
    d->paused_ = v;
    d->roundInfo_->setPaused(v);
    d->model_->setPaused(v);
    emit pausedChanged(v);
}

void TimeController::updateRoundInfo()
{
    int row;
    const TimeItem *item = d->model_->getCurrent(row);
    QDateTime end, cur(QDateTime::currentDateTime());
    QString nextName = "", nextBreakName = "", nextBreakEnd = "", nextBreakStart;
    QString name = item[0].name_;
    int playing = item[0].type_ == TimeModel::Play ? 1 : 0;
    int next = 1;
    end = cur;


    if (item[0].type_ != TimeModel::End) {

        while (item[next].type_ == TimeModel::Change)
            next++;
        nextName = item[next].name_;
        while (item[next].type_ == TimeModel::Change ||
                item[next].type_ == TimeModel::Play)
            next++;
        nextBreakName = item[next].name_;
        end = item[1].start_;
        if (item[next].type_ == TimeModel::Break)
            nextBreakEnd = d->model_->data(d->model_->index(row + next), EndRole).toString();
        if (item[next].type_ == TimeModel::Break ||
                item[next].type_ == TimeModel::End)
            nextBreakStart = d->model_->data(d->model_->index(row + next), StartRole).toString();

        if (item[0].start_ >= cur) {
            end = item[0].start_;
            name = "Kilpailun alkuun";
        }
    } else {
        playing = 2;
    }
    d->roundInfo_->setRow(row);
    qulonglong e = d->model_->data(
                d->model_->index(
                    row + 1 < d->model_->rowCount(QModelIndex()) ?
                        row + 1 : row),
                StartTimeRole).toULongLong() / 1000;
    d->roundInfo_->setEnd(e);
    d->roundInfo_->setName(name);
    d->roundInfo_->setNextName(nextName);
    d->roundInfo_->setNextBreakName(nextBreakName);
    d->roundInfo_->setNextBreakEnd(nextBreakEnd);
    d->roundInfo_->setNextBreakStart(nextBreakStart);
    d->roundInfo_->setPlaying(playing);
    d->roundInfo_->setPaused(d->paused_);
}

RoundInfo *TimeController::getRoundInfo()
{
    if (d->roundInfo_)
        return d->roundInfo_;
    d->roundInfo_ = new RoundInfo();
    updateRoundInfo();
    d->roundInfo_->connect(d->model_, SIGNAL(dataChanged(QModelIndex,QModelIndex)), SIGNAL(roundInfoChanged()));
    connect(d->roundInfo_, SIGNAL(roundInfoChanged()), SLOT(updateRoundInfo()));
    return d->roundInfo_;
}

QString TimeController::tournamentEnd() const
{
    return d->model_->data(d->model_->index(d->model_->rowCount(QModelIndex()) - 1),
            StartRole).toString();
}

TimeModel * TimeController::getModel()
{
    return d->model_;
}

void TimeController::resetModel()
{
    TimeModel *m = d->model_;
    d->model_ = new TimeModel();
    d->model_->setRounds(m->rounds());
    d->model_->setRoundTime(m->roundTime());
    d->model_->setRoundBreak(m->roundBreak());
    d->model_->setStartTime(m->startTime());
    d->model_->setPaused(d->paused_);
    emit modelChanged();
    updateRoundInfo();
    d->roundInfo_->connect(d->model_, SIGNAL(dataChanged(QModelIndex,QModelIndex)), SIGNAL(roundInfoChanged()));
    m->deleteLater();
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
    QFileInfo cur = d->resultUrl_.right(d->resultUrl_.size() - 7);
    if (info.isDir()) {
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
    d->urlTimer_->start(100);
}

void TimeController::setResultUrl(const QString &url)
{
    d->resultUrl_ = url;
    delete d->watcher_;
    d->watcher_ = NULL;
    d->urlTimer_->start(1000);
}
