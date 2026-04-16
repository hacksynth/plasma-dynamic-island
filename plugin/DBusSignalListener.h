#pragma once

#include <QDBusMessage>
#include <QObject>
#include <QQmlEngine>
#include <QStringList>
#include <QVariant>
#include <QVariantList>

// Handle returned by DBusSignalListener.call(). Emits finished() once the
// underlying QDBusPendingCall completes. QML holds the JS ownership so the
// object lives until the JS reference is released.
class DBusPendingReply : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("DBusPendingReply is returned by DBusSignalListener.call()")

public:
    explicit DBusPendingReply(QObject *parent = nullptr);

Q_SIGNALS:
    void finished(bool success, const QVariant &result, const QString &error);
};

// Minimal QML wrapper for arbitrary org.freedesktop.DBus session-bus signal
// subscription, plus outbound async method calls via call(). ZERO business
// logic — only translates DBus signals into a uniform QML signal and
// forwards method calls. See CLAUDE.md "Pure QML + JavaScript" exception.
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

    // Async outbound D-Bus method call. args is the parameter list in
    // method-signature order. signature is an optional D-Bus signature
    // string (e.g. "susssasa{sv}i") used to coerce JS values to the
    // expected wire types — needed because QML has no uint32, an empty
    // JS array marshals as `av` not `as`, etc. Pass "" to disable coercion.
    // The returned DBusPendingReply emits finished(success, result, error).
    Q_INVOKABLE DBusPendingReply *call(const QString &service,
                                       const QString &path,
                                       const QString &iface,
                                       const QString &method,
                                       const QVariantList &args,
                                       const QString &signature = QString());

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
