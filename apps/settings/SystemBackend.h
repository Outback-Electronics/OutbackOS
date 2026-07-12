#pragma once

#include <QObject>
#include <QProcess>
#include <QString>
#include <QStringList>
#include <QVariantList>

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
    Q_INVOKABLE void startWifiScan();
    Q_INVOKABLE bool connectWifi(
        const QString &ssid,
        const QString &password
    );

    Q_INVOKABLE bool bluetoothEnabled() const;
    Q_INVOKABLE bool setBluetoothEnabled(bool enabled);
    Q_INVOKABLE void startBluetoothScan();

    Q_INVOKABLE QString kernelVersion() const;
    Q_INVOKABLE QString operatingSystem() const;
    Q_INVOKABLE QString checkForUpdates();

    bool wifiScanning() const;
    bool bluetoothScanning() const;

signals:
    void wifiScanningChanged();
    void bluetoothScanningChanged();

    void wifiScanFinished(
        const QVariantList &networks,
        const QString &error
    );

    void bluetoothScanFinished(
        const QVariantList &devices,
        const QString &error
    );

private:
    struct CommandResult {
        int exitCode;
        QString standardOutput;
        QString standardError;

        bool succeeded() const
        {
            return exitCode == 0;
        }
    };

    CommandResult run(
        const QString &program,
        const QStringList &arguments = {}
    ) const;

    QVariantList parseWifiNetworks(
        const QString &output
    ) const;

    QVariantList parseBluetoothDevices(
        const QString &output
    ) const;

    QProcess m_wifiScanProcess;
    QProcess m_bluetoothScanProcess;

    bool m_wifiScanning = false;
    bool m_bluetoothScanning = false;
};
