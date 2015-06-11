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

#pragma once

#include <QAbstractListModel>
#include <QDateTime>

class TimeModel;
class RefItem;

class CompactModel : public QAbstractListModel {
    Q_OBJECT

    const TimeModel *model_;
    std::vector <RefItem> items_;
    Q_ENUMS(Roles)

    void pushRef(RefItem &i, int &j);

public:
    explicit CompactModel(const TimeModel *m = 0);

    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;

    QHash<int, QByteArray> roleNames() const override;

    enum Roles {
        StartRole = Qt::UserRole + 1,
        NameRole,
    };
public slots:
    void updateRefs(QModelIndex tl, QModelIndex br);
};

struct RefItem {
    int first_, last_;
    QDateTime start_;
    std::string name_;

    bool operator!=(const RefItem &) const;
};
