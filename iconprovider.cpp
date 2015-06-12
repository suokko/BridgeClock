#include "iconprovider.h"

#include <QIcon>
#include <QDebug>

IconProvider::IconProvider() :
    QQuickImageProvider(QQmlImageProviderBase::Pixmap,
        QQmlImageProviderBase::ForceAsynchronousImageLoading)
{
}

QPixmap IconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
#if 1
    QIcon icon = QIcon::fromTheme(id, QIcon(":/icons/" + id + ".png"));
#else
    QIcon icon(":/icons/" + id + ".png");
#endif

    QSize targetsize(24, 24);

    if (requestedSize.isValid())
        targetsize = requestedSize;

    QPixmap r = icon.pixmap(targetsize);
    if (size)
        *size = r.size();

    return r;
}
