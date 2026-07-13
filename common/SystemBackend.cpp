#include <QVariantMap>
#include <algorithm>
#include "SystemBackend.h"

#include <QDir>
#include <QFile>
#include <QMap>
#include <QProcess>
#include <QRegularExpression>
#include <QSysInfo>

namespace {

// The first /sys/class/power_supply entry whose "type" is "Battery".
// Desktops and most VMs have no such entry, which callers treat as
// "no battery" rather than an error.
QString batterySupplyPath()
{
    QDir supplies(QStringLiteral("/sys/class/power_supply"));

    const QStringList entries = supplies.entryList(
        QDir::Dirs | QDir::NoDotAndDotDot
    );

    for (const QString &entry : entries) {
        const QString path = supplies.filePath(entry);

        QFile typeFile(path + QStringLiteral("/type"));

        if (!typeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            continue;
        }

        if (
            QString::fromUtf8(typeFile.readAll()).trimmed()
            == QStringLiteral("Battery")
        ) {
            return path;
        }
    }

    return QString();
}

} // namespace

SystemBackend::SystemBackend(QObject *parent)
    : QObject(parent)
{
}

QString SystemBackend::deviceName() const
{
    const auto result = CommandRunner::run(
        QStringLiteral("hostnamectl"),
        {
            QStringLiteral("--static")
        }
    );

    if (result.succeeded() && !result.standardOutput.isEmpty()) {
        return result.standardOutput;
    }

    return QSysInfo::machineHostName();
}

bool SystemBackend::renameDevice(const QString &name)
{
    const QString cleaned = name.trimmed();

    static const QRegularExpression validName(
        QStringLiteral("^[A-Za-z0-9][A-Za-z0-9-]{0,62}$")
    );

    if (!validName.match(cleaned).hasMatch()) {
        return false;
    }

    const auto result = CommandRunner::run(
        QStringLiteral("pkexec"),
        {
            QStringLiteral("hostnamectl"),
            QStringLiteral("set-hostname"),
            cleaned
        }
    );

    return result.succeeded();
}

int SystemBackend::brightness() const
{
    const auto result = CommandRunner::run(
        QStringLiteral("brightnessctl"),
        {
            QStringLiteral("-m")
        }
    );

    if (!result.succeeded()) {
        return -1;
    }

    const QStringList fields =
        result.standardOutput.split(QLatin1Char(','));

    if (fields.size() < 4) {
        return -1;
    }

    QString value = fields.at(3);
    value.remove(QLatin1Char('%'));

    bool ok = false;
    const int percentage = value.toInt(&ok);

    return ok ? percentage : -1;
}

bool SystemBackend::setBrightness(int percentage)
{
    percentage = qBound(1, percentage, 100);

    const auto result = CommandRunner::run(
        QStringLiteral("brightnessctl"),
        {
            QStringLiteral("set"),
            QString::number(percentage) + QStringLiteral("%")
        }
    );

    return result.succeeded();
}

int SystemBackend::volume() const
{
    const auto result = CommandRunner::run(
        QStringLiteral("wpctl"),
        {
            QStringLiteral("get-volume"),
            QStringLiteral("@DEFAULT_AUDIO_SINK@")
        }
    );

    if (!result.succeeded()) {
        return -1;
    }

    static const QRegularExpression expression(
        QStringLiteral("Volume:\\s*([0-9.]+)")
    );

    const auto match = expression.match(result.standardOutput);

    if (!match.hasMatch()) {
        return -1;
    }

    bool ok = false;
    const double rawVolume = match.captured(1).toDouble(&ok);

    return ok
        ? qBound(0, qRound(rawVolume * 100.0), 150)
        : -1;
}

bool SystemBackend::setVolume(int percentage)
{
    percentage = qBound(0, percentage, 150);

    const QString value =
        QString::number(percentage) + QStringLiteral("%");

    const auto result = CommandRunner::run(
        QStringLiteral("wpctl"),
        {
            QStringLiteral("set-volume"),
            QStringLiteral("@DEFAULT_AUDIO_SINK@"),
            value
        }
    );

    return result.succeeded();
}

bool SystemBackend::audioMuted() const
{
    const auto result = CommandRunner::run(
        QStringLiteral("wpctl"),
        {
            QStringLiteral("get-volume"),
            QStringLiteral("@DEFAULT_AUDIO_SINK@")
        }
    );

    return result.succeeded()
        && result.standardOutput.contains(
            QStringLiteral("[MUTED]"),
            Qt::CaseInsensitive
        );
}

bool SystemBackend::setAudioMuted(bool muted)
{
    const auto result = CommandRunner::run(
        QStringLiteral("wpctl"),
        {
            QStringLiteral("set-mute"),
            QStringLiteral("@DEFAULT_AUDIO_SINK@"),
            muted
                ? QStringLiteral("1")
                : QStringLiteral("0")
        }
    );

    return result.succeeded();
}

bool SystemBackend::wifiEnabled() const
{
    const auto result = CommandRunner::run(
        QStringLiteral("nmcli"),
        {
            QStringLiteral("-t"),
            QStringLiteral("-f"),
            QStringLiteral("WIFI"),
            QStringLiteral("radio")
        }
    );

    return result.succeeded()
        && result.standardOutput.compare(
            QStringLiteral("enabled"),
            Qt::CaseInsensitive
        ) == 0;
}

bool SystemBackend::setWifiEnabled(bool enabled)
{
    const auto result = CommandRunner::run(
        QStringLiteral("nmcli"),
        {
            QStringLiteral("radio"),
            QStringLiteral("wifi"),
            enabled
                ? QStringLiteral("on")
                : QStringLiteral("off")
        }
    );

    return result.succeeded();
}

QString SystemBackend::activeNetwork() const
{
    const auto result = CommandRunner::run(
        QStringLiteral("nmcli"),
        {
            QStringLiteral("-t"),
            QStringLiteral("-f"),
            QStringLiteral("ACTIVE,SSID"),
            QStringLiteral("device"),
            QStringLiteral("wifi"),
            QStringLiteral("list")
        }
    );

    if (!result.succeeded()) {
        return QStringLiteral("Unavailable");
    }

    const QStringList lines = result.standardOutput.split(
        QLatin1Char('\n'),
        Qt::SkipEmptyParts
    );

    for (const QString &line : lines) {
        if (
            line.startsWith(QStringLiteral("yes:"))
            || line.startsWith(QStringLiteral("*:"))
        ) {
            const int separator = line.indexOf(QLatin1Char(':'));

            if (separator >= 0 && separator + 1 < line.size()) {
                return line.mid(separator + 1);
            }
        }
    }

    return QStringLiteral("Not connected");
}



QStringList SystemBackend::savedWifiNetworks() const
{
    QStringList names;

    const auto result = CommandRunner::run(
        QStringLiteral("nmcli"),
        {
            QStringLiteral("-t"),
            QStringLiteral("-f"),
            QStringLiteral("NAME,TYPE"),
            QStringLiteral("connection"),
            QStringLiteral("show")
        }
    );

    if (!result.succeeded()) {
        return names;
    }

    const QStringList lines = result.standardOutput.split(
        QLatin1Char('\n'),
        Qt::SkipEmptyParts
    );

    for (const QString &line : lines) {
        const int separator = line.lastIndexOf(QLatin1Char(':'));

        if (separator <= 0) {
            continue;
        }

        const QString type = line.mid(separator + 1);

        if (
            type == QStringLiteral("802-11-wireless")
            || type == QStringLiteral("wifi")
        ) {
            names.append(line.left(separator));
        }
    }

    return names;
}

bool SystemBackend::connectWifi(
    const QString &ssid,
    const QString &password
)
{
    if (ssid.trimmed().isEmpty()) {
        return false;
    }

    QStringList arguments = {
        QStringLiteral("device"),
        QStringLiteral("wifi"),
        QStringLiteral("connect"),
        ssid
    };

    if (!password.isEmpty()) {
        arguments.append(QStringLiteral("password"));
        arguments.append(password);
    }

    return CommandRunner::run(
        QStringLiteral("nmcli"),
        arguments
    ).succeeded();
}

void SystemBackend::connectToNetwork(
    const QString &ssid,
    const QString &password
)
{
    if (m_wifiConnecting || ssid.trimmed().isEmpty()) {
        return;
    }

    m_wifiConnecting = true;
    emit wifiConnectingChanged();

    QStringList arguments = {
        QStringLiteral("device"),
        QStringLiteral("wifi"),
        QStringLiteral("connect"),
        ssid
    };

    if (!password.isEmpty()) {
        arguments.append(QStringLiteral("password"));
        arguments.append(password);
    }

    m_wifiConnectProcess.setProgram(QStringLiteral("nmcli"));
    m_wifiConnectProcess.setArguments(arguments);

    disconnect(
        &m_wifiConnectProcess,
        nullptr,
        this,
        nullptr
    );

    connect(
        &m_wifiConnectProcess,
        &QProcess::finished,
        this,
        [this, ssid](
            int exitCode,
            QProcess::ExitStatus exitStatus
        ) {
            const QString error = QString::fromUtf8(
                m_wifiConnectProcess.readAllStandardError()
            ).trimmed();

            m_wifiConnecting = false;
            emit wifiConnectingChanged();

            const bool success =
                exitStatus == QProcess::NormalExit
                && exitCode == 0;

            emit wifiConnectFinished(
                success,
                ssid,
                success
                    ? QString()
                    : (error.isEmpty()
                        ? QStringLiteral("Could not connect to %1").arg(ssid)
                        : error)
            );
        }
    );

    m_wifiConnectProcess.start();
}

bool SystemBackend::forgetNetwork(const QString &ssid)
{
    if (ssid.trimmed().isEmpty()) {
        return false;
    }

    return CommandRunner::run(
        QStringLiteral("nmcli"),
        {
            QStringLiteral("connection"),
            QStringLiteral("delete"),
            ssid
        }
    ).succeeded();
}

bool SystemBackend::bluetoothEnabled() const
{
    const auto result = CommandRunner::run(
        QStringLiteral("bluetoothctl"),
        {
            QStringLiteral("show")
        }
    );

    return result.succeeded()
        && result.standardOutput.contains(
            QStringLiteral("Powered: yes"),
            Qt::CaseInsensitive
        );
}

bool SystemBackend::setBluetoothEnabled(bool enabled)
{
    if (enabled) {
        const auto unblock = CommandRunner::run(
            QStringLiteral("pkexec"),
            {
                QStringLiteral("rfkill"),
                QStringLiteral("unblock"),
                QStringLiteral("bluetooth")
            }
        );

        if (!unblock.succeeded()) {
            return false;
        }
    }

    const auto result = CommandRunner::run(
        QStringLiteral("bluetoothctl"),
        {
            QStringLiteral("power"),
            enabled
                ? QStringLiteral("on")
                : QStringLiteral("off")
        }
    );

    return result.succeeded();
}

bool SystemBackend::batteryPresent() const
{
    return !batterySupplyPath().isEmpty();
}

int SystemBackend::batteryPercentage() const
{
    const QString path = batterySupplyPath();

    if (path.isEmpty()) {
        return -1;
    }

    QFile capacityFile(path + QStringLiteral("/capacity"));

    if (!capacityFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return -1;
    }

    bool ok = false;
    const int percentage = QString::fromUtf8(capacityFile.readAll())
        .trimmed()
        .toInt(&ok);

    return ok ? qBound(0, percentage, 100) : -1;
}

bool SystemBackend::batteryCharging() const
{
    const QString path = batterySupplyPath();

    if (path.isEmpty()) {
        return false;
    }

    QFile statusFile(path + QStringLiteral("/status"));

    if (!statusFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }

    const QString status =
        QString::fromUtf8(statusFile.readAll()).trimmed();

    return status == QStringLiteral("Charging")
        || status == QStringLiteral("Full");
}



QString SystemBackend::kernelVersion() const
{
    return QSysInfo::kernelType()
        + QStringLiteral(" ")
        + QSysInfo::kernelVersion();
}

QString SystemBackend::operatingSystem() const
{
    QFile file(QStringLiteral("/etc/os-release"));

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QSysInfo::prettyProductName();
    }

    const QString contents = QString::fromUtf8(file.readAll());
    const QStringList lines = contents.split(QLatin1Char('\n'));

    for (const QString &line : lines) {
        if (!line.startsWith(QStringLiteral("PRETTY_NAME="))) {
            continue;
        }

        QString value = line.mid(12).trimmed();

        if (
            value.startsWith(QLatin1Char('"'))
            && value.endsWith(QLatin1Char('"'))
        ) {
            value = value.mid(1, value.size() - 2);
        }

        return value;
    }

    return QSysInfo::prettyProductName();
}

QString SystemBackend::checkForUpdates()
{
    const auto refresh = CommandRunner::run(
        QStringLiteral("pkexec"),
        {
            QStringLiteral("apt-get"),
            QStringLiteral("update")
        }
    );

    if (!refresh.succeeded()) {
        return refresh.standardError.isEmpty()
            ? QStringLiteral("Update check failed")
            : refresh.standardError;
    }

    const auto simulation = CommandRunner::run(
        QStringLiteral("apt-get"),
        {
            QStringLiteral("--simulate"),
            QStringLiteral("upgrade")
        }
    );

    if (!simulation.succeeded()) {
        return QStringLiteral("Could not inspect available updates");
    }

    int count = 0;

    const QStringList lines =
        simulation.standardOutput.split(QLatin1Char('\n'));

    for (const QString &line : lines) {
        if (line.startsWith(QStringLiteral("Inst "))) {
            ++count;
        }
    }

    return count == 0
        ? QStringLiteral("Your system is up to date")
        : QStringLiteral("%1 updates available").arg(count);
}

bool SystemBackend::wifiScanning() const
{
    return m_wifiScanning;
}

bool SystemBackend::bluetoothScanning() const
{
    return m_bluetoothScanning;
}

bool SystemBackend::wifiConnecting() const
{
    return m_wifiConnecting;
}

bool SystemBackend::installingUpdates() const
{
    return m_installingUpdates;
}

void SystemBackend::installUpdates()
{
    if (m_installingUpdates) {
        return;
    }

    m_installingUpdates = true;
    emit installingUpdatesChanged();

    m_updatesInstallProcess.setProgram(QStringLiteral("pkexec"));
    m_updatesInstallProcess.setArguments({
        QStringLiteral("apt-get"),
        QStringLiteral("-y"),
        QStringLiteral("upgrade")
    });

    disconnect(
        &m_updatesInstallProcess,
        nullptr,
        this,
        nullptr
    );

    connect(
        &m_updatesInstallProcess,
        &QProcess::finished,
        this,
        [this](
            int exitCode,
            QProcess::ExitStatus exitStatus
        ) {
            const QString error = QString::fromUtf8(
                m_updatesInstallProcess.readAllStandardError()
            ).trimmed();

            m_installingUpdates = false;
            emit installingUpdatesChanged();

            const bool success =
                exitStatus == QProcess::NormalExit
                && exitCode == 0;

            emit updatesInstallFinished(
                success,
                success
                    ? QStringLiteral("Updates installed successfully")
                    : (error.isEmpty()
                        ? QStringLiteral("Could not install updates")
                        : error)
            );
        }
    );

    m_updatesInstallProcess.start();
}

bool SystemBackend::setAutoLockMinutes(int minutes)
{
    CommandRunner::run(
        QStringLiteral("pkill"),
        {
            QStringLiteral("-x"),
            QStringLiteral("swayidle")
        }
    );

    if (minutes <= 0) {
        return true;
    }

    return QProcess::startDetached(
        QStringLiteral("swayidle"),
        {
            QStringLiteral("-w"),
            QStringLiteral("timeout"),
            QString::number(minutes * 60),
            QStringLiteral("/usr/bin/outback-lock")
        }
    );
}

bool SystemBackend::lockScreenNow()
{
    return QProcess::startDetached(
        QStringLiteral("/usr/bin/outback-lock")
    );
}

bool SystemBackend::autoUpdatesEnabled() const
{
    return CommandRunner::run(
        QStringLiteral("systemctl"),
        {
            QStringLiteral("is-enabled"),
            QStringLiteral("--quiet"),
            QStringLiteral("apt-daily-upgrade.timer")
        }
    ).succeeded();
}

bool SystemBackend::setAutoUpdatesEnabled(bool enabled)
{
    return CommandRunner::run(
        QStringLiteral("pkexec"),
        {
            QStringLiteral("outback-toggle-autoupdates"),
            enabled
                ? QStringLiteral("on")
                : QStringLiteral("off")
        }
    ).succeeded();
}

bool SystemBackend::offlineMode() const
{
    const auto result = CommandRunner::run(
        QStringLiteral("nmcli"),
        {
            QStringLiteral("networking")
        }
    );

    return result.succeeded()
        && result.standardOutput.compare(
            QStringLiteral("disabled"),
            Qt::CaseInsensitive
        ) == 0;
}

bool SystemBackend::setOfflineMode(bool enabled)
{
    return CommandRunner::run(
        QStringLiteral("nmcli"),
        {
            QStringLiteral("networking"),
            enabled
                ? QStringLiteral("off")
                : QStringLiteral("on")
        }
    ).succeeded();
}

bool SystemBackend::nightColourEnabled() const
{
    return CommandRunner::run(
        QStringLiteral("pgrep"),
        {
            QStringLiteral("-x"),
            QStringLiteral("gammastep")
        }
    ).succeeded();
}

bool SystemBackend::setNightColour(bool enabled)
{
    if (enabled) {
        m_nightColourProcess.setProgram(QStringLiteral("gammastep"));
        m_nightColourProcess.setArguments({
            QStringLiteral("-O"),
            QStringLiteral("4500")
        });
        m_nightColourProcess.start();

        return true;
    }

    CommandRunner::run(
        QStringLiteral("pkill"),
        {
            QStringLiteral("-x"),
            QStringLiteral("gammastep")
        }
    );

    return true;
}

QVariantList SystemBackend::parseWifiNetworks(
    const QString &output
) const
{
    QVariantList networks;
    QMap<QString, QVariantMap> strongest;

    const QStringList lines = output.split(
        QLatin1Char('\n'),
        Qt::SkipEmptyParts
    );

    for (const QString &line : lines) {
        const QStringList fields =
            line.split(QLatin1Char('\t'));

        if (fields.size() < 3) {
            continue;
        }

        const QString ssid = fields.at(0).trimmed();

        if (ssid.isEmpty()) {
            continue;
        }

        bool signalOk = false;
        const int signal = fields.at(1).toInt(&signalOk);

        QVariantMap network;
        network.insert(QStringLiteral("ssid"), ssid);
        network.insert(
            QStringLiteral("signal"),
            signalOk ? signal : 0
        );
        network.insert(
            QStringLiteral("security"),
            fields.at(2).trimmed()
        );

        if (
            !strongest.contains(ssid)
            || strongest.value(ssid)
                   .value(QStringLiteral("signal"))
                   .toInt() < signal
        ) {
            strongest.insert(ssid, network);
        }
    }

    for (const QVariantMap &network : strongest) {
        networks.append(network);
    }

    std::sort(
        networks.begin(),
        networks.end(),
        [](const QVariant &left, const QVariant &right) {
            return left.toMap()
                       .value(QStringLiteral("signal"))
                       .toInt()
                > right.toMap()
                       .value(QStringLiteral("signal"))
                       .toInt();
        }
    );

    return networks;
}

void SystemBackend::startWifiScan()
{
    if (m_wifiScanning) {
        return;
    }

    m_wifiScanning = true;
    emit wifiScanningChanged();

    m_wifiScanProcess.setProgram(
        QStringLiteral("nmcli")
    );

    m_wifiScanProcess.setArguments({
        QStringLiteral("-t"),
        QStringLiteral("--escape"),
        QStringLiteral("no"),
        QStringLiteral("-f"),
        QStringLiteral("SSID,SIGNAL,SECURITY"),
        QStringLiteral("device"),
        QStringLiteral("wifi"),
        QStringLiteral("list"),
        QStringLiteral("--rescan"),
        QStringLiteral("yes")
    });

    disconnect(
        &m_wifiScanProcess,
        nullptr,
        this,
        nullptr
    );

    connect(
        &m_wifiScanProcess,
        &QProcess::finished,
        this,
        [this](
            int exitCode,
            QProcess::ExitStatus exitStatus
        ) {
            const QString output = QString::fromUtf8(
                m_wifiScanProcess.readAllStandardOutput()
            );

            const QString error = QString::fromUtf8(
                m_wifiScanProcess.readAllStandardError()
            ).trimmed();

            m_wifiScanning = false;
            emit wifiScanningChanged();

            if (
                exitStatus != QProcess::NormalExit
                || exitCode != 0
            ) {
                emit wifiScanFinished(
                    {},
                    error.isEmpty()
                        ? QStringLiteral("Wi-Fi scan failed")
                        : error
                );

                return;
            }

            QString tabSeparated = output;

            const QStringList lines = output.split(
                QLatin1Char('\n'),
                Qt::SkipEmptyParts
            );

            QStringList converted;

            for (const QString &line : lines) {
                QStringList fields =
                    line.split(QLatin1Char(':'));

                if (fields.size() < 3) {
                    continue;
                }

                converted.append(
                    fields.at(0)
                    + QLatin1Char('\t')
                    + fields.at(1)
                    + QLatin1Char('\t')
                    + fields.mid(2).join(
                        QStringLiteral(":")
                    )
                );
            }

            tabSeparated = converted.join(
                QLatin1Char('\n')
            );

            emit wifiScanFinished(
                parseWifiNetworks(tabSeparated),
                {}
            );
        }
    );

    m_wifiScanProcess.start();
}

QVariantList SystemBackend::parseBluetoothDevices(
    const QString &output
) const
{
    QVariantList devices;

    const QStringList lines = output.split(
        QLatin1Char('\n'),
        Qt::SkipEmptyParts
    );

    for (const QString &line : lines) {
        if (!line.startsWith(QStringLiteral("Device "))) {
            continue;
        }

        const QStringList fields = line.split(
            QLatin1Char(' '),
            Qt::SkipEmptyParts
        );

        if (fields.size() < 3) {
            continue;
        }

        QVariantMap device;
        device.insert(
            QStringLiteral("address"),
            fields.at(1)
        );
        device.insert(
            QStringLiteral("name"),
            fields.mid(2).join(QStringLiteral(" "))
        );

        devices.append(device);
    }

    return devices;
}

void SystemBackend::startBluetoothScan()
{
    if (m_bluetoothScanning) {
        return;
    }

    if (!bluetoothEnabled()) {
        if (!setBluetoothEnabled(true)) {
            emit bluetoothScanFinished(
                {},
                QStringLiteral(
                    "Bluetooth could not be enabled"
                )
            );

            return;
        }
    }

    m_bluetoothScanning = true;
    emit bluetoothScanningChanged();

    m_bluetoothScanProcess.setProgram(
        QStringLiteral("bluetoothctl")
    );

    m_bluetoothScanProcess.setArguments({
        QStringLiteral("--timeout"),
        QStringLiteral("10"),
        QStringLiteral("scan"),
        QStringLiteral("on")
    });

    disconnect(
        &m_bluetoothScanProcess,
        nullptr,
        this,
        nullptr
    );

    connect(
        &m_bluetoothScanProcess,
        &QProcess::finished,
        this,
        [this](
            int exitCode,
            QProcess::ExitStatus exitStatus
        ) {
            const QString scanError = QString::fromUtf8(
                m_bluetoothScanProcess
                    .readAllStandardError()
            ).trimmed();

            QProcess devicesProcess;

            devicesProcess.start(
                QStringLiteral("bluetoothctl"),
                {
                    QStringLiteral("devices")
                }
            );

            devicesProcess.waitForFinished(3000);

            const QString devicesOutput =
                QString::fromUtf8(
                    devicesProcess
                        .readAllStandardOutput()
                );

            m_bluetoothScanning = false;
            emit bluetoothScanningChanged();

            if (
                exitStatus != QProcess::NormalExit
                || exitCode != 0
            ) {
                emit bluetoothScanFinished(
                    {},
                    scanError.isEmpty()
                        ? QStringLiteral(
                            "Bluetooth scan failed"
                        )
                        : scanError
                );

                return;
            }

            emit bluetoothScanFinished(
                parseBluetoothDevices(devicesOutput),
                {}
            );
        }
    );

    m_bluetoothScanProcess.start();
}
