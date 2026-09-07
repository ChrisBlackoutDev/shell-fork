#include <qbytearray.h>
#include <qcoreapplication.h>
#include <qcryptographichash.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qtemporarydir.h>
#include <qtest.h>
#include <qurl.h>

#include "../filesystemmodel.hpp"

using caelestia::models::FileSystemEntry;
using Qt::StringLiterals::operator""_s;

class ThumbnailTest : public QObject {
    Q_OBJECT

private slots:
    void resolvesFreedesktopThumbnail();
    void prefersLargestCachedThumbnail();
    void returnsEmptyWhenThumbnailIsMissing();
};

QString thumbnailName(const QString& path) {
    const auto uri = QUrl::fromLocalFile(path).toEncoded();
    return QString::fromLatin1(QCryptographicHash::hash(uri, QCryptographicHash::Md5).toHex()) + u".png"_s;
}

bool writeThumbnail(const QString& path) {
    static const auto kPng = QByteArray::fromBase64(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=");

    if (!QDir().mkpath(QFileInfo(path).absolutePath()))
        return false;

    QFile thumbnail(path);
    return thumbnail.open(QIODevice::WriteOnly) && thumbnail.write(kPng) == kPng.size();
}

void ThumbnailTest::resolvesFreedesktopThumbnail() {
    QTemporaryDir files;
    QVERIFY(files.isValid());

    const auto mediaPath = files.filePath(u"clip # 例.mp4"_s);
    QFile media(mediaPath);
    QVERIFY(media.open(QIODevice::WriteOnly));
    media.close();

    const auto expected =
        QDir::cleanPath(qEnvironmentVariable("XDG_CACHE_HOME") + u"/thumbnails/large/"_s + thumbnailName(mediaPath));
    QVERIFY(writeThumbnail(expected));

    const FileSystemEntry entry(mediaPath, u"clip # 例.mp4"_s);
    QCOMPARE(entry.thumbnailPath(), expected);
}

void ThumbnailTest::prefersLargestCachedThumbnail() {
    QTemporaryDir files;
    QVERIFY(files.isValid());

    const auto mediaPath = files.filePath(u"model.stl"_s);
    QFile media(mediaPath);
    QVERIFY(media.open(QIODevice::WriteOnly));
    media.close();

    const auto name = thumbnailName(mediaPath);
    const auto cacheHome = qEnvironmentVariable("XDG_CACHE_HOME");
    const auto normal = QDir::cleanPath(cacheHome + u"/thumbnails/normal/"_s + name);
    const auto largest = QDir::cleanPath(cacheHome + u"/thumbnails/xx-large/"_s + name);

    for (const auto& path : { normal, largest }) {
        QVERIFY(writeThumbnail(path));
    }

    const FileSystemEntry entry(mediaPath, u"model.stl"_s);
    QCOMPARE(entry.thumbnailPath(), largest);
}

void ThumbnailTest::returnsEmptyWhenThumbnailIsMissing() {
    QTemporaryDir files;
    QVERIFY(files.isValid());

    const auto mediaPath = files.filePath(u"document.pdf"_s);
    QFile media(mediaPath);
    QVERIFY(media.open(QIODevice::WriteOnly));
    media.close();

    const FileSystemEntry entry(mediaPath, u"document.pdf"_s);
    QVERIFY(entry.thumbnailPath().isEmpty());
}

int main(int argc, char* argv[]) {
    QTemporaryDir cache;
    if (!cache.isValid())
        return 1;

    qputenv("XDG_CACHE_HOME", cache.path().toUtf8());
    QCoreApplication app(argc, argv);
    ThumbnailTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "thumbnailtest.moc"
