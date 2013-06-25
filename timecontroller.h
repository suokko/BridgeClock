#ifndef TIMECONTROLLER_H
#define TIMECONTROLLER_H

#include <QObject>
#include <QDateTime>

class TimeModel;
class RoundInfo;
class QQuickItem;
class QFileSystemWatcher;
class QQuickWindow;

class TimeController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(unsigned rounds READ rounds WRITE setRounds)
    Q_PROPERTY(unsigned roundTime READ roundTime WRITE setRoundTime)
    Q_PROPERTY(unsigned roundBreak READ roundBreak WRITE setRoundBreak)
    Q_PROPERTY(QDateTime startTime READ startTime WRITE setStartTime)
    Q_PROPERTY(QString resultUrl READ resultUrl WRITE setResultUrl)

public:
    explicit TimeController();
    ~TimeController();
    void setRounds(unsigned);
    void setRoundTime(unsigned);
    void setRoundBreak(unsigned);
    void setStartTime(const QDateTime &);
    unsigned rounds() const;
    unsigned roundTime() const;
    unsigned roundBreak() const;
    const QDateTime &startTime() const;

    const QString &resultUrl() const;
    void setResultUrl(const QString &url);

    Q_INVOKABLE TimeModel *getModel();
    Q_INVOKABLE RoundInfo *getRoundInfo() const;
    Q_INVOKABLE void setItemCursor(QQuickItem *obj, const QString &cursor);

    Q_INVOKABLE void moveWindow(QQuickWindow *w, int dx, int dy);
    Q_INVOKABLE void startResize(QQuickWindow *w, QQuickItem *obj, int x, int y);
    Q_INVOKABLE void resizeWindow(QQuickWindow *w, QQuickItem *obj, int dx, int dy, const QString &dir);

signals:
    void updateResults(const QString &url);

public slots:
    void urlUpdate();
    void fileChanged(const QString &path);

private:
    class TimeControllerPrivate *d;

};

#endif // TIMECONTROLLER_H
