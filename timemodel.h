#ifndef TIMEMODEL_H
#define TIMEMODEL_H

#include <QAbstractListModel>
#include <vector>
#include <QDateTime>

struct TimeItem {
    enum Type {
        None,
        Play,
        Change,
        Break,
        End,
    } type_;
    QDateTime start_;
    QString name_;
    TimeItem(Type t = None, const QDateTime &start = QDateTime(), const QString & name = QString());
};

class TimeModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit TimeModel();
    int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role) const;

    void setRounds(unsigned);
    void setRoundTime(unsigned);
    void setRoundBreak(unsigned);
    void setStartTime(const QDateTime &);
    unsigned rounds() const;
    unsigned roundTime() const;
    unsigned roundBreak() const;
    const QDateTime &startTime() const;
    const TimeItem *getCurrent() const;

#if QT_VERSION >= QT_VERSION_CHECK(5, 0, 0)
    QHash<int, QByteArray> roleNames() const;
#endif
signals:

public slots:

private:
    unsigned rounds_;
    unsigned roundTime_;
    unsigned roundBreak_;
    QDateTime startTime_;

    std::vector<TimeItem> list_;

    void timeFixUp();

};

#endif // TIMEMODEL_H
