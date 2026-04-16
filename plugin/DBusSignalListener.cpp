#include "DBusSignalListener.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDebug>
#include <QQmlEngine>

DBusPendingReply::DBusPendingReply(QObject *parent)
    : QObject(parent)
{
}

DBusSignalListener::DBusSignalListener(QObject *parent)
    : QObject(parent)
{
}

DBusSignalListener::~DBusSignalListener()
{
    unsubscribe();
}

void DBusSignalListener::setService(const QString &v)
{
    if (m_service == v)
        return;
    m_service = v;
    Q_EMIT serviceChanged();
    resubscribe();
}

void DBusSignalListener::setPath(const QString &v)
{
    if (m_path == v)
        return;
    m_path = v;
    Q_EMIT pathChanged();
    resubscribe();
}

void DBusSignalListener::setIface(const QString &v)
{
    if (m_iface == v)
        return;
    m_iface = v;
    Q_EMIT ifaceChanged();
    resubscribe();
}

void DBusSignalListener::setSignalNames(const QStringList &v)
{
    if (m_signalNames == v)
        return;
    m_signalNames = v;
    Q_EMIT signalNamesChanged();
    resubscribe();
}

bool DBusSignalListener::isConfigured() const
{
    return !m_service.isEmpty() && !m_path.isEmpty()
        && !m_iface.isEmpty() && !m_signalNames.isEmpty();
}

void DBusSignalListener::setConnected(bool v)
{
    if (m_connected == v)
        return;
    m_connected = v;
    Q_EMIT connectedChanged();
}

void DBusSignalListener::setLastError(const QString &v)
{
    if (m_lastError == v)
        return;
    m_lastError = v;
    Q_EMIT lastErrorChanged();
}

void DBusSignalListener::unsubscribe()
{
    if (m_subscribedSignals.isEmpty())
        return;
    QDBusConnection bus = QDBusConnection::sessionBus();
    for (const QString &sig : std::as_const(m_subscribedSignals)) {
        bus.disconnect(m_service, m_path, m_iface, sig,
                       this, SLOT(onDBusMessage(QDBusMessage)));
    }
    m_subscribedSignals.clear();
    setConnected(false);
}

void DBusSignalListener::resubscribe()
{
    unsubscribe();

    if (!isConfigured())
        return;

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        const QString reason = QStringLiteral("session bus not connected");
        setLastError(reason);
        Q_EMIT subscriptionFailed(reason);
        return;
    }

    int successCount = 0;
    QStringList failures;
    for (const QString &sig : std::as_const(m_signalNames)) {
        const bool ok = bus.connect(m_service, m_path, m_iface, sig,
                                    this, SLOT(onDBusMessage(QDBusMessage)));
        if (ok) {
            m_subscribedSignals.append(sig);
            ++successCount;
        } else {
            failures.append(sig);
        }
    }

    if (!failures.isEmpty()) {
        const QString reason = QStringLiteral("failed to connect: ")
            + failures.join(QStringLiteral(", "));
        setLastError(reason);
        Q_EMIT subscriptionFailed(reason);
    } else {
        setLastError(QString());
    }

    setConnected(successCount > 0);
}

void DBusSignalListener::onDBusMessage(const QDBusMessage &message)
{
    Q_EMIT signalReceived(message.member(), message.arguments());
}

namespace {

// Split a D-Bus signature into per-argument complete types. Top-level
// complete types are 's', 'i', 'u', 'as', 'a{sv}', '(ii)', etc. We only
// need to recognize the outer tokens to map each to an argument.
QStringList splitSignature(const QString &sig)
{
    QStringList out;
    int i = 0;
    while (i < sig.size()) {
        const QChar c = sig.at(i);
        if (c == QLatin1Char('a')) {
            // array type: 'a' followed by a single complete type
            if (i + 1 >= sig.size()) {
                out.append(sig.mid(i));
                break;
            }
            const QChar next = sig.at(i + 1);
            if (next == QLatin1Char('{')) {
                // dict-entry: a{kv}
                int close = sig.indexOf(QLatin1Char('}'), i + 1);
                if (close < 0) { out.append(sig.mid(i)); break; }
                out.append(sig.mid(i, close - i + 1));
                i = close + 1;
            } else if (next == QLatin1Char('(')) {
                int depth = 1;
                int j = i + 2;
                while (j < sig.size() && depth > 0) {
                    if (sig.at(j) == QLatin1Char('(')) ++depth;
                    else if (sig.at(j) == QLatin1Char(')')) --depth;
                    ++j;
                }
                out.append(sig.mid(i, j - i));
                i = j;
            } else {
                out.append(sig.mid(i, 2));
                i += 2;
            }
        } else if (c == QLatin1Char('(')) {
            int depth = 1;
            int j = i + 1;
            while (j < sig.size() && depth > 0) {
                if (sig.at(j) == QLatin1Char('(')) ++depth;
                else if (sig.at(j) == QLatin1Char(')')) --depth;
                ++j;
            }
            out.append(sig.mid(i, j - i));
            i = j;
        } else {
            out.append(QString(c));
            ++i;
        }
    }
    return out;
}

// Coerce a single argument to the wire type requested by sigToken.
// Only covers the subset needed by realistic QML-to-service calls.
QVariant coerceArg(const QVariant &v, const QString &sigToken)
{
    if (sigToken.isEmpty()) return v;
    const QChar first = sigToken.at(0);
    if (first == QLatin1Char('u')) return QVariant::fromValue<quint32>(v.toUInt());
    if (first == QLatin1Char('i')) return QVariant::fromValue<qint32>(v.toInt());
    if (first == QLatin1Char('t')) return QVariant::fromValue<quint64>(v.toULongLong());
    if (first == QLatin1Char('x')) return QVariant::fromValue<qint64>(v.toLongLong());
    if (first == QLatin1Char('d')) return QVariant::fromValue<double>(v.toDouble());
    if (first == QLatin1Char('b')) return QVariant::fromValue<bool>(v.toBool());
    if (first == QLatin1Char('s') || first == QLatin1Char('o')
        || first == QLatin1Char('g')) {
        return QVariant::fromValue<QString>(v.toString());
    }
    if (sigToken == QLatin1String("as")) {
        QStringList out;
        const auto list = v.toList();
        for (const auto &e : list) out.append(e.toString());
        return QVariant::fromValue(out);
    }
    // a{sv} and other complex types: pass through; QVariantMap already
    // marshals as a{sv} when keys are string.
    return v;
}

} // namespace

DBusPendingReply *DBusSignalListener::call(const QString &service,
                                           const QString &path,
                                           const QString &iface,
                                           const QString &method,
                                           const QVariantList &args,
                                           const QString &signature)
{
    auto *reply = new DBusPendingReply();
    QQmlEngine::setObjectOwnership(reply, QQmlEngine::JavaScriptOwnership);

    auto msg = QDBusMessage::createMethodCall(service, path, iface, method);
    QVariantList outArgs = args;
    if (!signature.isEmpty()) {
        const QStringList tokens = splitSignature(signature);
        for (int i = 0; i < outArgs.size() && i < tokens.size(); ++i) {
            outArgs[i] = coerceArg(outArgs.at(i), tokens.at(i));
        }
    }
    msg.setArguments(outArgs);

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        const QString err = QStringLiteral("session bus not connected");
        QMetaObject::invokeMethod(reply, [reply, err]() {
            Q_EMIT reply->finished(false, QVariant(), err);
        }, Qt::QueuedConnection);
        return reply;
    }

    const QDBusPendingCall pending = bus.asyncCall(msg);
    auto *watcher = new QDBusPendingCallWatcher(pending, reply);
    QObject::connect(watcher, &QDBusPendingCallWatcher::finished,
        reply, [reply, watcher]() {
            if (watcher->isError()) {
                const auto err = watcher->error();
                Q_EMIT reply->finished(false, QVariant(),
                    err.name() + QStringLiteral(": ") + err.message());
            } else {
                const QDBusMessage replyMsg = watcher->reply();
                const QVariantList replyArgs = replyMsg.arguments();
                QVariant result;
                if (replyArgs.size() == 1) {
                    result = replyArgs.first();
                } else if (replyArgs.size() > 1) {
                    result = QVariant::fromValue(replyArgs);
                }
                Q_EMIT reply->finished(true, result, QString());
            }
            watcher->deleteLater();
        });

    return reply;
}
