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

#include <QObject>
#include <QtQml>

class RoundInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int row READ row NOTIFY rowChanged)
    Q_PROPERTY(qint64 end READ end NOTIFY endChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString nextName READ nextName NOTIFY nextNameChanged)
    Q_PROPERTY(QString nextBreakName READ nextBreakName NOTIFY nextBreakNameChanged)
    Q_PROPERTY(QString nextBreakEnd READ nextBreakEnd NOTIFY nextBreakEndChanged)
    Q_PROPERTY(QString nextBreakStart READ nextBreakStart NOTIFY nextBreakStartChanged)
    Q_PROPERTY(int playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(QString timeLeft READ timeLeft NOTIFY timeLeftChanged)

public:
    explicit RoundInfo();
    ~RoundInfo();

    int row() const;
    qint64 end() const;
    const QString &name() const;
    const QString &nextName() const;
    const QString &nextBreakName() const;
    const QString &nextBreakEnd() const;
    const QString &nextBreakStart() const;
    int playing() const;
    QString timeLeft() const;

    void setRow(int row);
    void setEnd(const qint64 &v);
    void setName(const QString &v);
    void setNextName(const QString &v);
    void setNextBreakName(const QString &v);
    void setNextBreakEnd(const QString &v);
    void setNextBreakStart(const QString &v);
    void setPlaying(int v);
    void setPaused(bool v);
signals:
    void rowChanged() const;
    void endChanged() const;
    void nameChanged() const;
    void nextNameChanged() const;
    void nextBreakNameChanged() const;
    void nextBreakEndChanged() const;
    void nextBreakStartChanged() const;
    void playingChanged() const;
    void timeLeftChanged() const;
    /**
     * @brief roundInfoChanged notifies that info has been likely to change
     */
    void roundInfoChanged() const;

public slots:
    void onTimeLeftTimer();

private:
    int row_;
    qint64 end_;
    QString name_;
    QString nextName_;
    QString nextBreakName_;
    QString nextBreakEnd_;
    QString nextBreakStart_;
    int playing_ : 3;
    bool paused_ : 1;
    class QTimer *timeLeftTimer_;
};
