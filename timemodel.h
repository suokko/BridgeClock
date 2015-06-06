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
class TimeModelVariant;

class TimeModel : public QAbstractListModel
{
    Q_OBJECT
    Q_ENUMS(Type)
    Q_ENUMS(Roles)
public:
    explicit TimeModel();
    ~TimeModel();
    Q_INVOKABLE int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role) const;

    enum Type {
        None,
        Play,
        Change,
        Break,
        End,
    };

    enum Roles {
        NameRole = Qt::UserRole+1,
        StartRole,
        EndRole,
        PreviousNameRole,
        EndMinuteRole,
        EndHourRole,
        EndTimeRole,
        TypeRole,
        StartTimeRole,
        NameRawRole,
        LengthRole,
    };

    void reset();
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
    Q_INVOKABLE TimeModelVariant *qmlData(int row, QString role) const;
signals:
    void roundsChanged();
    void roundTimeChanged();
    void roundBreakChanged();
    void startTimeChanged();

public slots:
    void onDataChangeTimeout();

    void languageChange();

private:
    unsigned rounds_ : 8;
    unsigned roundTime_ : 8;
    unsigned roundBreak_ : 8;
    unsigned paused_ : 1;
    QTime pauseTime_;
    QDateTime startTime_;
    class QTimer *dataChangeTimer_;
    QSettings settings_;

    std::vector<TimeItem> list_;

    void timeFixUp(bool loading = false);
    void readSettings();
    void writeTimeItem();
    void deleteTimeItem(int row, int end = -1);

    QDateTime pauseTimeAdjust(QDateTime t) const;
};

class TimeModelVariant : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged)
public:
    TimeModelVariant(const TimeModel *parent, int row, const QVariant &value);

    QVariant value();
    void setValue(const QVariant &v);
signals:
    void valueChanged();
private:
    int row_;
    QVariant value_;
};

struct TimeItem {
    TimeModel::Type type_;

    QDateTime start_;
    std::string name_;
    int timeDiff_;
    int nr_;
    TimeItem(TimeModel::Type t = TimeModel::None,
             const QDateTime &start = QDateTime(),
             const std::string &name = "",
             int nr = -1);

    void appendTime(int diff);
};

Q_DECLARE_METATYPE(TimeItem);


