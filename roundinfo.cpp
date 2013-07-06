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

#include "roundinfo.h"
#include <QTimer>
#include <QDateTime>

RoundInfo::RoundInfo() :
    QObject(),
    row_(-1),
    end_(0),
    name_(),
    nextName_(),
    playing_(-1),
    paused_(false),
    timeLeftTimer_(new QTimer())
{
    timeLeftTimer_->setSingleShot(false);
    connect(timeLeftTimer_, SIGNAL(timeout()), SLOT(onTimeLeftTimer()));
}

RoundInfo::~RoundInfo()
{
    delete timeLeftTimer_;
}

int RoundInfo::row() const
{
    return row_;
}

qint64 RoundInfo::end() const
{
    return end_;
}

const QString &RoundInfo::name() const
{
    return name_;
}

const QString &RoundInfo::nextName() const
{
    return nextName_;
}

int RoundInfo::playing() const
{
    return playing_;
}

void RoundInfo::setRow(int v)
{
    if (row_ == v)
        return;
    row_ = v;
    emit rowChanged();
}

void RoundInfo::setEnd(const qulonglong &v)
{
    if (end_ == v)
        return;
    end_ = v;
    emit endChanged();
    emit timeLeftChanged();
    if (playing_ < 2)
        QTimer::singleShot((end_ - QDateTime::currentDateTime().toTime_t())*1000,
                           this, SIGNAL(roundInfoChanged()));
}

void RoundInfo::setName(const QString &v)
{
    if (name_ == v)
        return;
    name_ = v;
    emit nameChanged();
}

void RoundInfo::setNextName(const QString &v)
{
    if (nextName_ == v)
        return;
    nextName_ = v;
    emit nextNameChanged();
}

void RoundInfo::setPlaying(int v)
{
    if (playing_ == v)
        return;
    if (playing_ == 2) {
        emit timeLeftChanged();
        QTimer::singleShot((end_ - QDateTime::currentDateTime().toTime_t())*1000,
                           this, SIGNAL(roundInfoChanged()));
    }
    if (v == 2)
        timeLeftTimer_->stop();
    playing_ = v;
    emit playingChanged();
}

void RoundInfo::setPaused(bool v)
{
    paused_ = v;
    if (paused_)
        timeLeftTimer_->stop();
    else if (playing_ < 2)
        timeLeftTimer_->start(1000);
}

QString RoundInfo::timeLeft() const
{
    if (playing_ < 2 && !paused_)
        timeLeftTimer_->start(1000);
    QDateTime end;
    end.setMSecsSinceEpoch(end_*1000);
    QTime r(0, 0);
    r = r.addMSecs(QDateTime::currentDateTime().msecsTo(end));
    if (r.hour() > 0)
        return r.toString("hh:mm:ss");
    else
        return r.toString("mm:ss");
}

void RoundInfo::onTimeLeftTimer()
{
    emit timeLeftChanged();
}
