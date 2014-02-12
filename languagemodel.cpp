/*
Copyright (c) 2014 Pauli Nieminen <suokkos@gmail.com>

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

#include "languagemodel.h"

#include <QDir>
#include <QRegExp>

#include <QSettings>
#include <QLocale>
#include <QCoreApplication>

#include <QVariant>

LanguageModel::LanguageModel()
{

    QDir localepath(QCoreApplication::applicationDirPath() + "/locale");
    QStringList filter("*.qm");
    QStringList files = localepath.entryList(filter);

    QString lang = "en";

    QSettings settings;

    QRegExp rx("BridgeClock_([^.]*).qm");
    for (const QString &f : files) {
        if (rx.exactMatch(f)) {
            QString l = rx.cap(1);
            translations_.append(l);
            QLocale loc(l);
            if (loc.language() == QLocale::system().language())
                lang = l;
        }
    }

    if (settings.contains("locale"))
        lang = settings.value("locale").toString();

    std::sort(translations_.begin(), translations_.end(),
            [](const QString &a, const QString &b) {
                QLocale al(a);
                QLocale bl(b);
                return QString::compare(al.nativeLanguageName(), bl.nativeLanguageName(), Qt::CaseInsensitive) < 0;
            });
    selected_ = 0;

    for (const QString &t : translations_) {
        if (t == lang)
            break;
        selected_++;
    }

    trans_.load("locale/BridgeClock_" + lang);
    qApp->installTranslator(&trans_);
}

#include <QDebug>

QHash<int, QByteArray> LanguageModel::roleNames() const
{
    static QHash<int, QByteArray> names;
    if (names.empty()) {
        names[NameRole] = "name";
    }
    return names;
}

int LanguageModel::rowCount(const QModelIndex &) const
{
    return translations_.size();
}

QVariant LanguageModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= (int)translations_.size())
        return QVariant();

    switch (role) {
    default:
        break;
    case NameRole:
    {
        QLocale loc(translations_.at(index.row()));
        return loc.nativeLanguageName();
    }
    }
    return QVariant();
}

void LanguageModel::setSelectedId(int id)
{
    if (id == selected_ || id < 0 || id >= (int)translations_.size())
        return;

    selected_ = id;
    trans_.load("locale/BridgeClock_" + translations_.at(id));
    QSettings settings;
    settings.setValue("locale", translations_.at(id));
    emit selectedChanged();
}

QString LanguageModel::emptyLang() const
{
    return "";
}

QString LanguageModel::selectedNative() const
{
    QLocale loc(translations_.at(selected_));
    return loc.nativeLanguageName();
}

int LanguageModel::selectedId() const
{
    return selected_;
}
