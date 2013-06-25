#ifndef ROUNDINFO_H
#define ROUNDINFO_H

#include <QObject>

class RoundInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(uint end READ end WRITE setEnd)
    Q_PROPERTY(QString name READ name WRITE setName)
    Q_PROPERTY(QString nextName READ nextName WRITE setNextName)
    Q_PROPERTY(int playing READ playing WRITE setPlaying)

public:
    explicit RoundInfo(uint end, const QString &name,
                       const QString &nextName, int playing);

    uint end() const;
    const QString &name() const;
    const QString &nextName() const;
    int playing() const;

    void setEnd(const uint &v);
    void setName(const QString &v);
    void setNextName(const QString &v);
    void setPlaying(int v);
signals:

public slots:

private:
    uint end_;
    QString name_;
    QString nextName_;
    int playing_;
};

#endif // ROUNDINFO_H
