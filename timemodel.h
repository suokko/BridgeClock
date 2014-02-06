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

#pragma once

#include <QAbstractListModel>
#include <vector>
#include <QDateTime>
#include <QtQml>

#include <stdint.h>

struct TimeItem;

class TimeModel : public QAbstractListModel
{
    Q_OBJECT
    Q_ENUMS(Type)
public:
    explicit TimeModel();
    ~TimeModel();
    int rowCount(const QModelIndex &parent) const;
    Q_INVOKABLE QVariant data(const QModelIndex &index, int role) const;

    enum Type {
        None,
        Play,
        Change,
        Break,
        End,
    };

    void setRounds(unsigned);
    void setRoundTime(unsigned);
    void setRoundBreak(unsigned);
    void setStartTime(const QDateTime &);
    void setPaused(bool v);
    unsigned rounds() const;
    unsigned roundTime() const;
    unsigned roundBreak() const;
    const QDateTime &startTime() const;
    const TimeItem *getCurrent(int &row) const;

    Q_INVOKABLE void changeType(int row, TimeModel::Type type,
                                const QString &name);
    Q_INVOKABLE void changeEnd(int row, QDateTime end);

    Q_INVOKABLE QHash<int, QByteArray> roleNames() const;
signals:

public slots:
    void onDataChangeTimeout();

private:
    unsigned rounds_ : 8;
    unsigned roundTime_ : 8;
    unsigned roundBreak_ : 8;
    unsigned paused_ : 1;
    QTime pauseTime_;
    QDateTime startTime_;
    class QTimer *dataChangeTimer_;

    std::vector<TimeItem> list_;

    void timeFixUp();

};

struct TimeItem {
    TimeModel::Type type_;

    QDateTime start_;
    QString name_;
    int timeDiff_;
    TimeItem(TimeModel::Type t = TimeModel::None,
             const QDateTime &start = QDateTime(),
             const QString & name = QString());

    void appendTime(int diff);
};


enum Roles {
    NameRole = Qt::UserRole+1,
    StartRole,
    EndRole,
    PreviousNameRole,
    EndMinuteRole,
    EndHourRole,
    TypeRole,
    StartTimeRole,
    NameRawRole,
};

