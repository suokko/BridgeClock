/*
Copyright (c) 2015 Pauli Nieminen <suokkos@gmail.com>

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

#include "compactmodel.h"
#include "timemodel.h"

CompactModel::CompactModel(const TimeModel *m) :
    QAbstractListModel(),
    model_(m)
{
    connect(m, &TimeModel::dataChanged, this, &CompactModel::updateRefs);
    updateRefs(m->index(0),m->index(m->rowCount(m->index(0))));
}

int CompactModel::rowCount(const QModelIndex &) const
{
    return items_.size();
}

QHash<int, QByteArray> CompactModel::roleNames() const
{
    static QHash<int, QByteArray> names;
    if (names.empty()) {
        names[StartRole] = "start";
        names[NameRole] = "name";
    }
    return names;
}

QVariant CompactModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= (int)items_.size())
        return QVariant();
    const RefItem &item = items_[index.row()];
    const TimeItem &time = model_->list_[item.first_];
    const TimeItem &timelast = model_->list_[item.last_];

    switch(role) {
    case StartRole:
        return QVariant(time.start_);
    case NameRole:
        //: Text shown to players in time table. This line correspounds to rounds from %1 to %2 inclusive
        const char *rounds = QT_TRANSLATE_NOOP("Break","Rounds %1-%2");
        if (item.first_ == item.last_) {
            if (time.nr_ > 0)
                return qApp->translate("Break", item.name_.c_str()).arg(time.nr_);
            else
                return qApp->translate("Break", item.name_.c_str());
        } else {
            return qApp->translate("Break", rounds).arg(time.nr_).arg(timelast.nr_);
        }
    }

    return QVariant();
}

void CompactModel::pushRef(RefItem &add, int &j)
{
    if (j == (int)items_.size()) {
        beginInsertRows(QModelIndex(), j, j);
        items_.push_back(add);
        endInsertRows();
    } else {
        if (add != items_[j]) {
            items_[j] = add;
            emit dataChanged(index(j),index(j));
        }
    }
    j++;
}

void CompactModel::updateRefs(QModelIndex, QModelIndex)
{
    int i = 0, j = 0;
    RefItem item;
    item.first_ = -1;
    item.last_ = -1;
    for (const TimeItem &time : model_->list_) {
        if (item.first_ == -1) {
            item.first_ = i;
            item.start_ = time.start_;
            QTime t = item.start_.time();
            t.setHMS(t.hour(), t.minute(), 0, 0);
            item.start_.setTime(t);
            item.name_ = time.name_;
        }
        if (time.type_ == TimeModel::Break ||
                time.type_ == TimeModel::End) {
            item.last_ = i - 1;
            pushRef(item, j);
            item.start_ = time.start_;
            item.first_ = i;
            item.last_ = i;
            item.name_ = time.name_;
            pushRef(item, j);
            item.first_ = -1;
        }
        i++;
    }

    if ((int)items_.size() > j) {
        beginRemoveRows(QModelIndex(), j, items_.size() - 1);
        items_.resize(j);
        endRemoveRows();
    }
}


bool RefItem::operator !=(const RefItem &o) const
{
    return first_ != o.first_ ||
            last_ != o.last_ ||
            name_ != o.name_ ||
            start_ != o.start_;
}
