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

#include "timemodel.h"
#include <QDateTime>
#include <QTimer>
#include <QDebug>

#include <algorithm>

#include <cassert>

enum Roles {
    NameRole = Qt::UserRole+1,
    StartRole,
    EndRole,
    PreviousNameRole,
    EndMinuteRole,
    EndHourRole,
    TypeRole,
    StartTimeRole,
};

TimeItem::TimeItem(TimeModel::Type type, const QDateTime &start, const QString &name) :
    type_(type),
    start_(start),
    name_(name),
    timeDiff_(0)
{

}

void TimeItem::appendTime(int diff)
{
    timeDiff_ += diff;
}

QHash<int, QByteArray> TimeModel::roleNames() const
{
    static QHash<int, QByteArray> names;
    if (names.empty()) {
        names[NameRole] = "name";
        names[StartRole] = "start";
        names[EndRole] = "end";
        names[PreviousNameRole] = "previous";
        names[EndMinuteRole] = "endMinute";
        names[EndHourRole] = "endHour";
        names[TypeRole] = "type";
        names[StartTimeRole] = "startTime";
    }
    return names;
}

TimeModel::~TimeModel()
{
    delete dataChangeTimer_;
}

TimeModel::TimeModel() :
    QAbstractListModel(),
    rounds_(13),
    roundTime_(15*2),
    roundBreak_(2*2),
    startTime_(QDateTime::currentDateTime()),
    dataChangeTimer_(new QTimer)
{
    dataChangeTimer_->setSingleShot(true);
    connect(dataChangeTimer_, SIGNAL(timeout()), SLOT(onDataChangeTimeout()));
    startTime_.setTime(QTime(startTime_.time().hour(), startTime_.time().minute()));
    unsigned r;
    list_.reserve(rounds_*2 + 2);
    QDateTime start = startTime_;
    const QString kierros = "Kierros ";
    const QString vaihto = "Vaihto";
    for (r = 0; r < rounds_; r++) {
        list_.push_back(TimeItem(Play, start, kierros + QString::number(r + 1)));
        start = start.addSecs(30 * roundTime_);
        if (r + 1 == rounds_)
            break;
        list_.push_back(TimeItem(Change, start, vaihto));
        start = start.addSecs(30 * roundBreak_);
    }
    list_.push_back(TimeItem(End, start, "Loppu"));
    onDataChangeTimeout();
}

void TimeModel::onDataChangeTimeout()
{
    int row;
    int msecs;
    QDateTime dt = QDateTime::currentDateTime();
    const TimeItem *item = getCurrent(row);
    if (row  + 1 == list_.size()) {
        // End of tournament
        dataChangeTimer_->stop();
        return;
    }
    if (row >= 0)
        // Tournament running
        msecs = dt.msecsTo(item[1].start_);
    else
        // Before begin of tournament
        msecs = dt.msecsTo(item->start_);
    if ((quint64)item->start_.msecsTo(dt) < 5000)
        emit dataChanged(index(row - 1 >= 0 ? row - 1 : 0), index(row));
    dataChangeTimer_->start(msecs);
}

int TimeModel::rowCount(const QModelIndex &parent) const
{
    (void)parent;
    return list_.size();
}

QVariant TimeModel::data(const QModelIndex &index, int role) const
{
    switch (role) {
    case NameRole:
    {
        QDateTime dt = QDateTime::currentDateTime();
        if (index.row() + 1 < list_.size() &&
                list_[index.row()].start_ < dt &&
                list_[index.row() + 1].start_ > dt) {
            return QString("<b>") + list_[index.row()].name_ + QString("</b>");
        }
        return list_[index.row()].name_;
    }
    case StartRole:
    {
        QString start = list_[index.row()].start_.toString("HH:mm:ss");
        QDateTime dt = QDateTime::currentDateTime();
        if (index.row() + 1 < list_.size() &&
                list_[index.row()].start_ < dt &&
                list_[index.row() + 1].start_ > dt) {
            return QString("<b>") + start + QString("</b>");
        }
        return start;
    }
    case EndRole:
        if (index.row() + 1 == list_.size())
            return list_[index.row()].start_.toString("HH:mm:ss");
        return list_[index.row() + 1].start_.toString("HH:mm:ss");
    case PreviousNameRole:
        if (index.row() == 0)
            return "Alku";
        return list_[index.row() - 1].name_;
    case EndMinuteRole:
        if (index.row() + 1 == list_.size())
            return list_[index.row()].start_.time().minute();
        return list_[index.row() + 1].start_.time().minute();
    case EndHourRole:
        if (index.row() + 1 == list_.size())
            return list_[index.row()].start_.time().hour();
        return list_[index.row() + 1].start_.time().hour();
    case TypeRole:
        return list_[index.row()].type_;
    case StartTimeRole:
        return list_[index.row()].start_.toMSecsSinceEpoch();
    default:
        return QVariant();
    }
}

unsigned TimeModel::rounds() const
{
    return rounds_;
}

unsigned TimeModel::roundTime() const
{
    return roundTime_;
}

unsigned TimeModel::roundBreak() const
{
    return roundBreak_;
}

const QDateTime & TimeModel::startTime() const
{
    return startTime_;
}

namespace {

struct cmp {
    unsigned nr_;
    cmp(unsigned nr) : nr_(nr)
    {
    }

    bool operator()(const TimeItem &v)
    {
        if (v.type_ != TimeModel::Play)
            return false;
        return nr_-- == 0;
    }
};
}

void TimeModel::setRounds(unsigned v)
{
    if (v > rounds_) {
        /* Append */
        unsigned nr = v - rounds_;
        list_.reserve(v*2 + 2);
        unsigned r;
        QDateTime start = startTime_;
        const QString kierros = "Kierros ";
        const QString vaihto = "Vaihto";
        TimeItem end = list_.back();
        beginInsertRows(QModelIndex(), list_.size() - 1, list_.size() + nr*2 - 2);
        list_.pop_back();
        for (r = 0; r < nr; r++) {
            list_.push_back(TimeItem(Change, start, vaihto));
            start.setTime(start.time().addSecs(30 * roundBreak_));
            list_.push_back(TimeItem(Play, start, kierros + QString::number(r + rounds_ + 1)));
            start.setTime(start.time().addSecs(30 * roundTime_));
        }
        list_.push_back(end);
        endInsertRows();
        timeFixUp();
    } else if (v < rounds_) {
        /* Delete */
        unsigned nr = rounds_ - v;
        cmp c(nr);

        std::vector<TimeItem>::reverse_iterator iter = std::find_if(list_.rbegin(), list_.rend(), c);
        unsigned toDelete = iter - list_.rbegin();
        unsigned size = list_.size();
        TimeItem end = list_.back();
        beginRemoveRows(QModelIndex(), size - toDelete - 1, size - 2);
        list_.resize(size - toDelete);
        list_.push_back(end);
        endRemoveRows();
        timeFixUp();
    }
    rounds_ = v;
}

void TimeModel::timeFixUp()
{
    QDateTime start = startTime_;
    unsigned r;
    int first = list_.size();
    int last = 0;
    for (r = 0; r < list_.size(); r++) {
        if (list_[r].start_ != start) {
            last = r;
            if (first > last)
                first = r;
            list_[r].start_ = start;
        }
        switch (list_[r].type_) {
        case Break:
        case Change:
            start = start.addSecs(30 * roundBreak_ + list_[r].timeDiff_);
            break;
        case Play:
            start = start.addSecs(30 * roundTime_ + list_[r].timeDiff_);
            break;
        case End:
            assert(r + 1 == list_.size());
            break;
        default:
            assert(false);
        }
    }
    if (last < first)
        return;
    QModelIndex s = index(first ? first - 1 : first);
    QModelIndex e = index(last);
    onDataChangeTimeout();
    emit dataChanged(s, e);
}

void TimeModel::setRoundTime(unsigned v)
{
    roundTime_ = v;
    timeFixUp();
}

void TimeModel::setRoundBreak(unsigned v)
{
    roundBreak_ = v;
    timeFixUp();
}

void TimeModel::setStartTime(const QDateTime &v)
{
    startTime_ = v;
    timeFixUp();
}

struct cmpTime {
    QDateTime cur_;
    cmpTime(const QDateTime &cur) : cur_(cur)
    {

    }

    bool operator()(const TimeItem &v)
    {
        return v.start_ > cur_;
    }
};

const TimeItem *TimeModel::getCurrent(int &row) const
{
    cmpTime c(QDateTime::currentDateTime());
    std::vector<TimeItem>::const_iterator iter =
            std::find_if(list_.begin(), list_.end(),
                         c);
    row = 0;
    if (iter != list_.begin())
        iter--;
    else
        row = -1;
    row += iter - list_.begin();
    return &*iter;
}

void TimeModel::changeType(int row, TimeModel::Type type,
                           const QString &name)
{
    if (list_[row].type_ != type ||
            list_[row].name_ != name) {
        list_[row].type_ = type;
        list_[row].name_ = name;
        if (type == Change)
            list_[row].timeDiff_ = 0;
        emit dataChanged(index(row), index(row));
        timeFixUp();
    }
}

void TimeModel::changeEnd(int row, QDateTime end)
{
    bool set = false;
    QDateTime dt = QDateTime::currentDateTime();
    if (row + 1 == list_.size()) {
        qWarning("The last entry shouldn't possible to modify. This is a bug!");
        return;
    }
    if (row == -1) {
        setStartTime(end);
        return;
    }
    if (end < list_[row].start_) {
        qWarning("Trying to select time before of start of item. This is a UI bug!");
        qDebug() << list_[row + 1].start_ << "->" << end << " = " << list_[row + 1].start_.secsTo(end);
        end = list_[row].start_;
        set = true;
    }
    set = set || end == list_[row].start_;
    if (set || list_[row + 1].start_ != end) {
        list_[row].appendTime(list_[row + 1].start_.secsTo(end));
        timeFixUp();
    }
}
