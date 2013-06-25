#include "timemodel.h"
#include <QDateTime>
#include <QDebug>

#include <algorithm>

#include <cassert>

enum Roles {
  NameRole = Qt::UserRole+1,
  StartRole,
};

TimeItem::TimeItem(TimeItem::Type type, const QDateTime &start, const QString &name) :
    type_(type),
    start_(start),
    name_(name)
{

}

QHash<int, QByteArray> TimeModel::roleNames() const
{
    static QHash<int, QByteArray> names;
    if (names.empty()) {
        names[NameRole] = "name";
        names[StartRole] = "start";
    }
    return names;
}

TimeModel::TimeModel() :
    QAbstractListModel(),
    rounds_(13),
    roundTime_(15*2),
    roundBreak_(2*2),
    startTime_(QDateTime::currentDateTime())
{
    startTime_.setTime(QTime(startTime_.time().hour(), startTime_.time().minute()));

    unsigned r;
    list_.reserve(rounds_*2 + 2);
    QDateTime start = startTime_;
    const QString kierros = "Kierros ";
    const QString vaihto = "Vaihto";
    for (r = 0; r < rounds_; r++) {
        list_.push_back(TimeItem(TimeItem::Play, start, kierros + QString::number(r + 1)));
        start = start.addSecs(30 * roundTime_);
        if (r + 1 == rounds_)
            break;
        list_.push_back(TimeItem(TimeItem::Change, start, vaihto));
        start = start.addSecs(30 * roundBreak_);
    }
    list_.push_back(TimeItem(TimeItem::End, start, "Loppu"));
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
        return list_[index.row()].name_;
    case StartRole:
    {
        QString start = list_[index.row()].start_.toString("HH:mm:ss");
        return start;
    }
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
        if (v.type_ != TimeItem::Play)
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
            list_.push_back(TimeItem(TimeItem::Change, start, vaihto));
            start.setTime(start.time().addSecs(30 * roundBreak_));
            list_.push_back(TimeItem(TimeItem::Play, start, kierros + QString::number(r + rounds_ + 1)));
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
    for (r = 0; r < list_.size(); r++) {
        list_[r].start_ = start;
        switch (list_[r].type_) {
        case TimeItem::Change:
            start = start.addSecs(30 * roundBreak_);
            break;
        case TimeItem::Play:
            start = start.addSecs(30 * roundTime_);
            break;
        case TimeItem::End:
            assert(r + 1 == list_.size());
            break;
        default:
            assert(false);
        }
    }
    QModelIndex s = index(0);
    QModelIndex e = index(list_.size() - 1);
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

const TimeItem *TimeModel::getCurrent() const
{
    cmpTime c(QDateTime::currentDateTime());
    std::vector<TimeItem>::const_iterator iter =
            std::find_if(list_.begin(), list_.end(),
                         c);
    if (iter != list_.begin())
        iter--;
    return &*iter;
}
