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

#include "versionchecker.h"
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QXmlStreamReader>
#include <QSettings>
#include <QString>

struct VersionCheckerPrivate {
	VersionChecker *p_;
	QString oldversion_;
	QNetworkAccessManager net_;

	VersionCheckerPrivate(VersionChecker *p, QString version);
};

VersionChecker::VersionChecker(const QString &version) :
	QObject(),
	d(new VersionCheckerPrivate(this, version))
{
}

VersionChecker::~VersionChecker()
{
	delete d;
}

static const QUrl url("https://googledrive.com/host/0B4izKEmfNQIBajhOOGZqR2JmNXM/BridgeClock-versions.xml");


VersionCheckerPrivate::VersionCheckerPrivate(VersionChecker *p, QString version) :
	p_(p),
	oldversion_(version),
	net_()
{
	QSettings settings;
	QDateTime lastcheck = settings.value("upgradecheck", QDateTime()).value<QDateTime>();
	bool newversion = settings.value("newversion", false).value<bool>();

	if (!newversion && lastcheck.isValid() && lastcheck.daysTo(QDateTime::currentDateTime()) < 7) {
		p_->deleteLater();
		return;
	}
	p_->connect(&net_, SIGNAL(finished(QNetworkReply*)), SLOT(downloaded(QNetworkReply*)));
	QNetworkRequest req(url);
	net_.get(req);
}

#include <list>

struct version {
	QString version;
	QString linux;
	QString win32;
};

typedef std::list<version> verlist;

void VersionChecker::downloaded(QNetworkReply *reply)
{
	if (reply->error() == QNetworkReply::NoError) {
		QXmlStreamReader xml(reply);
		QXmlStreamReader::TokenType token;

		version ver;
		verlist versions;

		while(!xml.atEnd() && !xml.hasError()) {
			/* Read next element.*/
			token = xml.readNext();
			/* If token is just StartDocument, we'll go to next.*/
			switch (token) {
			case QXmlStreamReader::StartDocument:
				break;
			case QXmlStreamReader::EndDocument:
				break;
			case QXmlStreamReader::StartElement:
				if (xml.name() == "build")
					ver.version = xml.attributes().value("version").toString();
				if (xml.name() == "Linux")
					ver.linux = xml.attributes().value("file").toString();
				if (xml.name() == "Windows")
					ver.win32 = xml.attributes().value("file").toString();
				break;
			case QXmlStreamReader::EndElement:
				if (xml.name() == "build")
					versions.push_back(ver);
				break;
			case QXmlStreamReader::Characters:
			case QXmlStreamReader::NoToken:
			case QXmlStreamReader::DTD:
			case QXmlStreamReader::Invalid:
			case QXmlStreamReader::Comment:
			case QXmlStreamReader::EntityReference:
			case QXmlStreamReader::ProcessingInstruction:
				break;
			}
		}

		versions.sort([](const version &a, const version &b) {return a.version > b.version;});

		QSettings settings;

		if (versions.front().version > d->oldversion_) {
#if defined(WIN32) || defined(__WIN32)
			emit newversion(versions.front().win32, versions.front().version);
#else
			emit newversion(versions.front().linux, versions.front().version);
#endif
			settings.setValue("newversion", true);
		} else {
			settings.setValue("newversion", false);
		}

		settings.setValue("upgradecheck", QDateTime::currentDateTime());
	} else {
		qWarning() << "Failed to load" << url << "with error" << reply->error();
	}
	reply->deleteLater();
	deleteLater();
}

