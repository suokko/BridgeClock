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
    Q_PROPERTY(bool showResults READ showResults WRITE setShowResults NOTIFY showResultsChanged)
    Q_PROPERTY(bool paused READ paused WRITE setPaused NOTIFY pausedChanged)
    Q_PROPERTY(TimeModel *model READ getModel NOTIFY modelChanged)
    Q_PROPERTY(RoundInfo *roundInfo READ getRoundInfo NOTIFY roundInfoChanged)

public:
    explicit TimeController();
    ~TimeController();
    void setRounds(unsigned);
    void setRoundTime(unsigned);
    void setRoundBreak(unsigned);
    void setStartTime(const QDateTime &);
    void setShowResults(bool v);
    void setPaused(bool v);
    unsigned rounds() const;
    unsigned roundTime() const;
    unsigned roundBreak() const;
    const QDateTime &startTime() const;
    bool showResults() const;
    bool paused() const;

    const QString &resultUrl() const;
    void setResultUrl(const QString &url);

    TimeModel *getModel();
    Q_INVOKABLE void resetModel();
    Q_INVOKABLE RoundInfo *getRoundInfo();
    Q_INVOKABLE void setItemCursor(QQuickItem *obj, const QString &cursor);

signals:
    void updateResults(const QString &url);
    void modelChanged();
    void roundInfoChanged();
    void showResultsChanged();
    void pausedChanged(bool paused);

public slots:
    void urlUpdate();
    void fileChanged(const QString &path);
    void updateRoundInfo();

private:
    class TimeControllerPrivate *d;

};

