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
#include <QSettings>

#include <algorithm>

#include <cassert>

TimeItem::TimeItem(TimeModel::Type type, const QDateTime &start, const std::string &name, int nr) :
    type_(type),
    start_(start),
    name_(name),
    timeDiff_(0),
    nr_(nr)
{

}

void TimeItem::appendTime(int diff)
{
    timeDiff_ += diff;
}

namespace {
template<class T>
class registerType {
public:
    registerType() {
        qRegisterMetaTypeStreamOperators<T>();
    }
};

registerType<TimeItem> timeItemRegister;

}

QDataStream &operator<<(QDataStream &ds, const std::string &v)
{
    QByteArray str(v.c_str(), v.length());
    return ds << str;
}

QDataStream &operator>>(QDataStream &ds, std::string &v)
{
    QByteArray str;
    ds >> str;
    v = std::string(str.constData(), str.length());
    return ds;
}

QDataStream &operator<<(QDataStream &ds, const TimeItem &v)
{
    int type = v.type_;
    return ds << type << v.name_ << v.timeDiff_ << v.nr_;
}
QDataStream &operator>>(QDataStream &ds, TimeItem &v)
{
    int type;
    ds >> type >> v.name_ >> v.timeDiff_ >> v.nr_;
    v.type_ = static_cast<TimeModel::Type>(type);
    return ds;
}

TimeModelVariant::TimeModelVariant(const TimeModel *p, int row, const QVariant &v) :
    QObject(),
    row_(row),
    value_(v)
{
    connect(p, SIGNAL(dataChanged(QModelIndex,QModelIndex)),SIGNAL(valueChanged()));
}

QVariant TimeModelVariant::value()
{
    return value_;
}

void TimeModelVariant::setValue(const QVariant &v)
{
    if (v == value_)
        return;
    value_ = v;
    emit valueChanged();
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
        names[EndTimeRole] = "endTime";
        names[TypeRole] = "type";
        names[StartTimeRole] = "startTime";
        names[NameRawRole] = "nameRaw";
        names[LengthRole] = "length";
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
    paused_(false),
    startTime_(QDateTime::currentDateTime()),
    dataChangeTimer_(new QTimer)
{
    dataChangeTimer_->setSingleShot(true);
    connect(dataChangeTimer_, SIGNAL(timeout()), SLOT(onDataChangeTimeout()));
    startTime_.setTime(QTime(startTime_.time().hour(), startTime_.time().minute()));
    unsigned r;
    list_.reserve(rounds_*2 + 2);
    QDateTime start = startTime_;
    for (r = 0; r < rounds_; r++) {
        list_.push_back(TimeItem(Play, start, "Round %1", r + 1));
        start = start.addSecs(30 * roundTime_);
        if (r + 1 == rounds_)
            break;
        list_.push_back(TimeItem(Change, start, "Change"));
        start = start.addSecs(30 * roundBreak_);
    }
    list_.push_back(TimeItem(End, start, "End"));
    readSettings();
    onDataChangeTimeout();
}

void TimeModel::readSettings()
{
    int rounds = settings_.value("rounds", rounds_).toInt();
    rounds_ = rounds;
    int roundTime = settings_.value("roundTime", roundTime_).toInt();
    roundTime_ = roundTime;
    int roundBreak = settings_.value("roundBreak", roundBreak_).toInt();
    roundBreak_ = roundBreak;
    QTime startTime = settings_.value("startTime", startTime_).toTime();
    QDateTime dt = QDateTime::currentDateTime();
    dt.setTime(startTime);
    startTime_ = dt;
    int size = settings_.beginReadArray("timeItems");
    std::vector<TimeItem> list;
    list.resize(size);
    for (int i = 0; i < size; i++) {
        settings_.setArrayIndex(i);
        list[i] = settings_.value("item").value<TimeItem>();
        if (list[i].type_ < Play || list[i].type_ > End) {
            list.clear();
            break;
        }
    }
    settings_.endArray();
    if (!list.empty())
        list_.swap(list);
    timeFixUp(true);
}

void TimeModel::onDataChangeTimeout()
{
    int row;
    int msecs;
    if (paused_) {
        int row;
        getCurrent(row);
        emit dataChanged(index(row + 1), index(list_.size() - 1));
        return;
    }
    QDateTime dt = QDateTime::currentDateTime();
    const TimeItem *item = getCurrent(row);
    if (row  + 1 == (int)list_.size()) {
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

#define align_to(v, a) ((v / a) * a)

QDateTime TimeModel::pauseTimeAdjust(QDateTime t) const
{
    QDateTime dt = QDateTime::currentDateTime();
    int elapsed;
    if (paused_) {
        elapsed = align_to(pauseTime_.elapsed(), 1000);
        dt = dt.addMSecs(-1 * elapsed);
        if (t > dt)
            t = t.addMSecs(elapsed);
    }
    return t;
}

TimeModelVariant *TimeModel::qmlData(int row, QString role) const
{
    if (row == -1 || row >= (int)list_.size()) {
        qWarning() << row << "passed for a row with role " << role;
        return new TimeModelVariant(this, -1, QVariant());
    }
    return new TimeModelVariant(this, row, data(index(row), roleNames().key(role.toUtf8().data(), -1)));
}

QVariant TimeModel::data(const QModelIndex &index, int role) const
{
    switch (role) {
    case NameRole:
    case NameRawRole:
    {
        (void)QT_TRANSLATE_NOOP("Break","Lunch");
        (void)QT_TRANSLATE_NOOP("Break","Dinner");
        (void)QT_TRANSLATE_NOOP("Break","Coffee");
        QDateTime dt = QDateTime::currentDateTime();
        QString translate;
        if (role == NameRawRole)
            translate = list_[index.row()].name_.c_str();
        else if (list_[index.row()].nr_ >= 0)
            translate = qApp->translate("Break",list_[index.row()].name_.c_str()).arg(list_[index.row()].nr_);
        else
            translate = qApp->translate("Break",list_[index.row()].name_.c_str());

        if (paused_)
            dt = dt.addMSecs(-1 * align_to(pauseTime_.elapsed(), 1000));
        if (role == NameRole && index.row() + 1 < (int)list_.size() &&
                list_[index.row()].start_ < dt &&
                list_[index.row() + 1].start_ > dt) {
            return QString("<b>") + translate + QString("</b>");
        }
        return translate;
    }
    case StartRole:
    {
        QDateTime start = list_[index.row()].start_;
        start = pauseTimeAdjust(start);
        QDateTime dt = QDateTime::currentDateTime();
        if (paused_)
            dt = dt.addMSecs(-1 * align_to(pauseTime_.elapsed(), 1000));
        if (index.row() + 1 < (int)list_.size() &&
                list_[index.row()].start_ < dt &&
                list_[index.row() + 1].start_ > dt) {
            return QString("<b>") + start.toString("HH:mm:ss") + QString("</b>");
        }
        return start.toString("HH:mm:ss");
    }
    case EndRole:
    {
        QDateTime start;
        if (index.row() + 1 == (int)list_.size())
            start = list_[index.row()].start_;
        else
            start = list_[index.row() + 1].start_;
        start = pauseTimeAdjust(start);
        return start.toString("HH:mm:ss");
    }
    case PreviousNameRole:
        if (index.row() == 0)
            //: Text visible in settings tab for previous round when first round is selected. Meaning the begin of tournament
            return tr("Begin");
        if (list_[index.row() - 1].nr_ >= 0)
            return qApp->translate("Break",list_[index.row() - 1].name_.c_str()).arg(list_[index.row() - 1].nr_);
        else
            return qApp->translate("Break",list_[index.row() - 1].name_.c_str());
    case EndMinuteRole:
    {
        QDateTime start;
        if (index.row() + 1 == (int)list_.size())
            start = list_[index.row()].start_;
        else
            start = list_[index.row() + 1].start_;
        start = pauseTimeAdjust(start);
        return start.time().minute();
    }
    case EndHourRole:
    {
        QDateTime start;
        if (index.row() + 1 == (int)list_.size())
            start = list_[index.row()].start_;
        else
            start = list_[index.row() + 1].start_;
        start = pauseTimeAdjust(start);
        return start.time().hour();
    }
    case EndTimeRole:
    {
        QDateTime start;
        if (index.row() + 1 == (int)list_.size())
            start = list_[index.row()].start_;
        else
            start = list_[index.row() + 1].start_;
        start = pauseTimeAdjust(start);
        return start;
    }
    case TypeRole:
        return list_[index.row()].type_;
    case StartTimeRole:
    {
        QDateTime start = list_[index.row()].start_;
        start = pauseTimeAdjust(start);
        return start.toMSecsSinceEpoch();
    }
    case LengthRole:
    {
        QDateTime end;
        if (index.row() + 1 == (int)list_.size())
            end = list_[index.row()].start_;
        else
            end = list_[index.row() + 1].start_;
        QDateTime start = list_[index.row()].start_;
        end = pauseTimeAdjust(end);
        start = pauseTimeAdjust(start);
        QTime diff(0,0);
        diff = diff.addSecs(start.secsTo(end));
        return diff.toString("HH:mm:ss");
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
        unsigned r, begin = list_.size() - 2, endrow;
        QDateTime start = startTime_;
        const std::string vaihto = QT_TRANSLATE_NOOP("Break","Change");
        TimeItem end = list_.back();
        beginInsertRows(QModelIndex(), list_.size() - 1, list_.size() + nr*2 - 2);
        list_.pop_back();
        for (r = 0; r < nr; r++) {
            list_.push_back(TimeItem(Change, start, vaihto));
            start.setTime(start.time().addSecs(30 * roundBreak_));
            //: The name of round. %1 is the number of round.
            list_.push_back(TimeItem(Play, start, QT_TRANSLATE_NOOP("Break","Round %1"), (r + rounds_ + 1)));
            start.setTime(start.time().addSecs(30 * roundTime_));
        }
        list_.push_back(end);
        endInsertRows();
        endrow = list_.size() - 1;
        writeTimeItem();
        timeFixUp();
    } else if (v < rounds_) {
        /* Delete */
        unsigned nr = rounds_ - v;
        cmp c(nr);

        std::vector<TimeItem>::reverse_iterator iter = std::find_if(list_.rbegin(), list_.rend(), c);
        unsigned toDelete = iter - list_.rbegin();
        unsigned size = list_.size();
        TimeItem end = list_.back();
        beginRemoveRows(QModelIndex(), size - toDelete, size - 2);
        list_.resize(size - toDelete);
        list_.push_back(end);
        endRemoveRows();
        deleteTimeItem(size -  toDelete + 1, size);
        writeTimeItem();
        timeFixUp();
    } else
        return;
    rounds_ = v;
    settings_.setValue("rounds", rounds_);
    emit roundsChanged();
}

void TimeModel::timeFixUp(bool loading)
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
            /* Breaks have fixed end time */
            if (!loading) {
                if (start > list_[r + 1].start_)
                    list_[r + 1].start_ = start;
                list_[r].timeDiff_ = start.secsTo(list_[r + 1].start_) - 30 * roundBreak_;
            }
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
    if (roundTime_ == v)
        return;
    roundTime_ = v;
    timeFixUp();
    writeTimeItem();
    settings_.setValue("roundTime", v);
    emit roundTimeChanged();
}

void TimeModel::setRoundBreak(unsigned v)
{
    if (roundBreak_ == v)
        return;
    roundBreak_ = v;
    timeFixUp();
    writeTimeItem();
    settings_.setValue("roundBreak", v);
    emit roundBreakChanged();
}

void TimeModel::setStartTime(const QDateTime &v)
{
    if (startTime_ == v)
        return;
    startTime_ = v;
    timeFixUp();
    writeTimeItem();
    settings_.setValue("startTime", v.time());
    emit startTimeChanged();
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
    int elapsed = 0;
    if (paused_)
        elapsed = pauseTime_.elapsed();
    cmpTime c(QDateTime::currentDateTime().addMSecs(-1* elapsed));
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
            list_[row].name_.compare(name.toUtf8().data()) != 0) {
        list_[row].type_ = type;
        list_[row].name_ = name.toUtf8().data();
        if (type == Change)
            list_[row].timeDiff_ = 0;
        timeFixUp();
        writeTimeItem();
        emit dataChanged(index(row), index(row));
    }
}

void TimeModel::setPaused(bool v)
{
    if (v) {
        paused_ = v;
        pauseTime_.restart();
        dataChangeTimer_->setSingleShot(false);
        dataChangeTimer_->start(1000);
    } else {
        int row;
        const TimeItem *item = getCurrent(row);
        /* Has to be after getCurrent but before changeEnd */
        paused_ = v;
        QDateTime end;
        if (row + 1 != (int)list_.size()) {
            int elapsed = pauseTime_.elapsed();
            end = item[1].start_;
            end = end.addMSecs(elapsed);
            changeEnd(row, end);
        }
        dataChangeTimer_->setSingleShot(true);
        onDataChangeTimeout();
    }
}

void TimeModel::changeEnd(int row, QDateTime end)
{
    bool set = false;
    QDateTime dt = QDateTime::currentDateTime();
    if (row + 1 == (int)list_.size()) {
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
        if (list_[row].type_ == Break)
            list_[row + 1].start_ = end;
        else
            list_[row].appendTime(list_[row + 1].start_.secsTo(end));
        timeFixUp();
        writeTimeItem();
    }
}

void TimeModel::writeTimeItem()
{
    settings_.beginWriteArray("timeItems");
    for (int row = 0; row < list_.size(); row++) {
        settings_.setArrayIndex(row);
        QVariant v;
        v.setValue(list_[row]);
        settings_.setValue("item", v);
    }
    settings_.endArray();
}

void TimeModel::deleteTimeItem(int start, int end)
{
    if (end == -1)
        end = start + 1;
    else
        end++;
    settings_.beginWriteArray("timeItems");
    for (int row = start; row < end; row++) {
        settings_.setArrayIndex(row);
        settings_.remove("item");
    }
    settings_.endArray();
}

void TimeModel::languageChange()
{
    emit dataChanged(index(0), index(list_.size() - 1));
}

void TimeModel::reset()
{
    int i = 0;
    int nr = 1;
    settings_.beginWriteArray("timeItems");
    for (TimeItem &t : list_) {
        t.timeDiff_ = 0;
        t.nr_ = -1;
        if (t.type_ == TimeModel::Break || t.type_ == TimeModel::Change) {
            t.type_ = TimeModel::Change;
            t.name_ = QT_TRANSLATE_NOOP("Break","Change");
        } else if (t.type_ == TimeModel::Play) {
            t.name_ = QT_TRANSLATE_NOOP("Break","Round %1");
            t.nr_ = nr++;
        } else if (t.type_ == TimeModel::End) {
            t.name_ = QT_TRANSLATE_NOOP("Break","End");
        }
        settings_.setArrayIndex(i++);
        QVariant v;
        v.setValue(t);
        settings_.setValue("item", v);
    }
    settings_.endArray();
    QModelIndex end;
    timeFixUp();
    writeTimeItem();
    emit dataChanged(index(0), index(list_.size() - 1));
}
