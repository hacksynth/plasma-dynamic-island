#include "DBusSignalListener.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDebug>

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
