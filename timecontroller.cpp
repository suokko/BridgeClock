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
#include "versionchecker.h"

#include <QDateTime>
#include <QTimer>

#include <QFileSystemWatcher>

#include <QDebug>

#include <QCursor>
#include <QQuickItem>
#include <QQuickWindow>
#include <QSettings>

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
    QSettings settings_;
    QString version_;
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
    d->zoomLimit_ = d->settings_.value("zoomLimit", QRect(-1,-1,-1,-1)).value<QRect>();
    d->resultUrl_ = d->settings_.value("url", "http://www.bridgefinland.fi").value<QString>();
    d->showResults_ = d->settings_.value("showResults", d->showResults_).value<bool>();

    connect(d->model_, SIGNAL(dataChanged(QModelIndex,QModelIndex)), SIGNAL(tournamentEndChanged()));
    connect(d->model_, SIGNAL(roundsChanged()), SIGNAL(roundsChanged()));
    connect(d->model_, SIGNAL(roundTimeChanged()), SIGNAL(roundTimeChanged()));
    connect(d->model_, SIGNAL(roundBreakChanged()), SIGNAL(roundBreakChanged()));
    connect(d->model_, SIGNAL(startTimeChanged()), SIGNAL(startTimeChanged()));

    d->model_->connect(this, SIGNAL(languageChanged()), SLOT(languageChange()));

    urlUpdate();
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

QString TimeController::getVersion() const
{
    return d->version_;
}

void TimeController::setVersion(const QString &v)
{
    const QString nonpublish = "julkaisematon";
    QString ver = v;
    if (v == "$(VERSION)")
        ver = nonpublish;
    if (d->version_ == ver)
        return;
    if (d->version_.isEmpty()) {
        /* Schedule version check */
        connect(new VersionChecker(ver == nonpublish ? "0" : ver), SIGNAL(newversion(const QString&, const QString&)),
                SIGNAL(newversion(const QString&, const QString&)));
    }
    d->version_ = ver;
    emit versionChanged();
}

void TimeController::setShowResults(bool v)
{
    if (v == d->showResults_)
        return;
    d->showResults_ = v;
    d->settings_.setValue("showResults", (bool)d->showResults_);
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
    d->settings_.setValue("zoomLimit", v);
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
    std::string nextName = "", nextBreakName = "";
    QString nextBreakEnd = "", nextBreakStart = "";
    int nrNext = -1, nrBreak = -1;
    std::string name = item[0].name_;
    int nr = item[0].nr_;
    int playing = item[0].type_ == TimeModel::Play ? 1 : 0;
    int next = 1;
    end = cur;


    if (item[0].type_ != TimeModel::End) {

        while (item[next].type_ == TimeModel::Change)
            next++;
        nextName = item[next].name_;
        nrNext = item[next].nr_;
        while (item[next].type_ == TimeModel::Change ||
                item[next].type_ == TimeModel::Play)
            next++;
        nextBreakName = item[next].name_;
        nrBreak = item[next].nr_;
        end = item[1].start_;
        if (item[next].type_ == TimeModel::Break)
            nextBreakEnd = d->model_->data(d->model_->index(row + next), EndRole).toString();
        if (item[next].type_ == TimeModel::Break ||
                item[next].type_ == TimeModel::End)
            nextBreakStart = d->model_->data(d->model_->index(row + next), StartRole).toString();

        if (item[0].start_ >= cur) {
            end = item[0].start_;
            //: The player visible text when count down shows time to begin of tournament. This should be fairly short text if possible.
            name = QT_TRANSLATE_NOOP("Break","Tournament begins");
            nr = -1;
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
    d->roundInfo_->setName(nr >= 0 ? qApp->translate("Break",name.c_str()).arg(nr) : qApp->translate("Break",name.c_str()));
    d->roundInfo_->setNextName(nrNext >= 0 ? qApp->translate("Break",nextName.c_str()).arg(nrNext) : qApp->translate("Break",nextName.c_str()));
    d->roundInfo_->setNextBreakName(nrBreak >= 0 ? qApp->translate("Break",nextBreakName.c_str()).arg(nrBreak) : qApp->translate("Break",nextBreakName.c_str()));
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
    d->model_->reset();
    updateRoundInfo();
    emit modelChanged();
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

void TimeController::languageChange()
{
    emit languageChanged();
}

void TimeController::setResultUrl(const QString &url)
{
    if (d->resultUrl_ != url)
        d->settings_.setValue("url", url);
    d->resultUrl_ = url;
    delete d->watcher_;
    d->watcher_ = NULL;
    d->urlTimer_->start(1000);
}
