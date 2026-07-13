#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QVariantList>

#include "CommandRunner.h"

class SystemBackend final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(
        bool wifiScanning
        READ wifiScanning
        NOTIFY wifiScanningChanged
    )

    Q_PROPERTY(
        bool bluetoothScanning
        READ bluetoothScanning
        NOTIFY bluetoothScanningChanged
    )

    Q_PROPERTY(
        bool wifiConnecting
        READ wifiConnecting
        NOTIFY wifiConnectingChanged
    )

    Q_PROPERTY(
        bool installingUpdates
        READ installingUpdates
        NOTIFY installingUpdatesChanged
    )

public:
    explicit SystemBackend(QObject *parent = nullptr);

    Q_INVOKABLE QString deviceName() const;
    Q_INVOKABLE bool renameDevice(const QString &name);

    Q_INVOKABLE int brightness() const;
    Q_INVOKABLE bool setBrightness(int percentage);

    Q_INVOKABLE int volume() const;
    Q_INVOKABLE bool setVolume(int percentage);
    Q_INVOKABLE bool audioMuted() const;
    Q_INVOKABLE bool setAudioMuted(bool muted);

    Q_INVOKABLE bool wifiEnabled() const;
    Q_INVOKABLE bool setWifiEnabled(bool enabled);
    Q_INVOKABLE QString activeNetwork() const;
    Q_INVOKABLE QStringList savedWifiNetworks() const;
    Q_INVOKABLE void startWifiScan();
    Q_INVOKABLE bool connectWifi(
        const QString &ssid,
        const QString &password
    );
    Q_INVOKABLE void connectToNetwork(
        const QString &ssid,
        const QString &password
    );
    Q_INVOKABLE bool forgetNetwork(const QString &ssid);

    Q_INVOKABLE bool bluetoothEnabled() const;
    Q_INVOKABLE bool setBluetoothEnabled(bool enabled);
    Q_INVOKABLE void startBluetoothScan();

    Q_INVOKABLE QString kernelVersion() const;
    Q_INVOKABLE QString operatingSystem() const;
    Q_INVOKABLE QString checkForUpdates();
    Q_INVOKABLE void installUpdates();

    Q_INVOKABLE bool autoUpdatesEnabled() const;
    Q_INVOKABLE bool setAutoUpdatesEnabled(bool enabled);

    Q_INVOKABLE bool offlineMode() const;
    Q_INVOKABLE bool setOfflineMode(bool enabled);

    Q_INVOKABLE bool nightColourEnabled() const;
    Q_INVOKABLE bool setNightColour(bool enabled);

    Q_INVOKABLE bool setAutoLockMinutes(int minutes);
    Q_INVOKABLE bool lockScreenNow();

    bool wifiScanning() const;
    bool bluetoothScanning() const;
    bool wifiConnecting() const;
    bool installingUpdates() const;

signals:
    void wifiScanningChanged();
    void bluetoothScanningChanged();
    void wifiConnectingChanged();
    void installingUpdatesChanged();

    void wifiScanFinished(
        const QVariantList &networks,
        const QString &error
    );

    void bluetoothScanFinished(
        const QVariantList &devices,
        const QString &error
    );

    void wifiConnectFinished(
        bool success,
        const QString &ssid,
        const QString &error
    );

    void updatesInstallFinished(
        bool success,
        const QString &message
    );

private:
    QVariantList parseWifiNetworks(
        const QString &output
    ) const;

    QVariantList parseBluetoothDevices(
        const QString &output
    ) const;

    QProcess m_wifiScanProcess;
    QProcess m_bluetoothScanProcess;
    QProcess m_wifiConnectProcess;
    QProcess m_nightColourProcess;
    QProcess m_updatesInstallProcess;

    bool m_wifiScanning = false;
    bool m_bluetoothScanning = false;
    bool m_wifiConnecting = false;
    bool m_installingUpdates = false;
};
