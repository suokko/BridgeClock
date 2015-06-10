#include "iconprovider.h"

#include <QIcon>
#include <QDebug>

IconProvider::IconProvider() :
    QQuickImageProvider(QQmlImageProviderBase::Pixmap,
        QQmlImageProviderBase::ForceAsynchronousImageLoading)
{
    /* Disable system icon source lookup to test windows behavior */
    QStringList test; test << ":/icons";
    QIcon::setThemeSearchPaths(test);
}

QPixmap IconProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    QIcon icon = QIcon::fromTheme(id);

    QSize targetsize(24, 24);

    if (requestedSize.isValid())
        targetsize = requestedSize;

    QPixmap r = icon.pixmap(targetsize);
    if (size)
        *size = r.size();

    return r;
}
