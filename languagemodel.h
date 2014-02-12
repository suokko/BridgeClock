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
#include <QTranslator>

class LanguageModel : public QAbstractListModel
{
    Q_OBJECT
    /* Empty string to force translation update in qml */
    Q_PROPERTY(QString lang READ emptyLang NOTIFY selectedChanged)
    Q_PROPERTY(QString selectedNative READ selectedNative NOTIFY selectedChanged)
    Q_PROPERTY(int selectedId READ selectedId WRITE setSelectedId NOTIFY selectedChanged)
public:
    explicit LanguageModel();

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

    Q_INVOKABLE QHash<int, QByteArray> roleNames() const;

    enum Roles {
        NameRole = Qt::UserRole + 1,
    };

    QString emptyLang() const;
    QString selectedNative() const;
    int selectedId() const;

    void setSelectedId(int id);
signals:
    void selectedChanged();

public slots:

private:
    QStringList translations_;
    int selected_;
    QTranslator trans_;
};
