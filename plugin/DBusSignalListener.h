#pragma once

#include <QDBusMessage>
#include <QObject>
#include <QQmlEngine>
#include <QStringList>
#include <QVariantList>

// Minimal QML wrapper for arbitrary org.freedesktop.DBus session-bus signal
// subscription. ZERO business logic — only translates DBus signals into a
// uniform QML signal. See CLAUDE.md "Pure QML + JavaScript" exception.
class DBusSignalListener : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString service READ service WRITE setService NOTIFY serviceChanged)
    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(QString iface READ iface WRITE setIface NOTIFY ifaceChanged)
    Q_PROPERTY(QStringList signalNames READ signalNames WRITE setSignalNames NOTIFY signalNamesChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    explicit DBusSignalListener(QObject *parent = nullptr);
    ~DBusSignalListener() override;

    QString service() const { return m_service; }
    QString path() const { return m_path; }
    QString iface() const { return m_iface; }
    QStringList signalNames() const { return m_signalNames; }
    bool connected() const { return m_connected; }
    QString lastError() const { return m_lastError; }

    void setService(const QString &v);
    void setPath(const QString &v);
    void setIface(const QString &v);
    void setSignalNames(const QStringList &v);

Q_SIGNALS:
    void signalReceived(const QString &signalName, const QVariantList &args);
    void serviceChanged();
    void pathChanged();
    void ifaceChanged();
    void signalNamesChanged();
    void connectedChanged();
    void lastErrorChanged();
    void subscriptionFailed(const QString &reason);

private Q_SLOTS:
    // Generic dispatcher: QDBusConnection delivers the raw QDBusMessage
    // here. We extract signal name from message.member() and forward to
    // QML via signalReceived.
    void onDBusMessage(const QDBusMessage &message);

private:
    void resubscribe();
    void unsubscribe();
    void setConnected(bool v);
    void setLastError(const QString &v);
    bool isConfigured() const;

    QString m_service;
    QString m_path;
    QString m_iface;
    QStringList m_signalNames;
    QStringList m_subscribedSignals; // signals successfully connected
    bool m_connected = false;
    QString m_lastError;
};
