#include "mpdListen.h"

// MPDListen Object
MPDListen::MPDListen(QObject *parent): QObject(parent), m_socket(new QTcpSocket(this)), m_reconnectTimer(new QTimer(this))
{
    // Ensure the Timer doesn't Loop as it does so by default
    m_reconnectTimer->setSingleShot(true);
    m_reconnectTimer->setInterval(2000);

    // Connect the Slots to their Proper Signals
    connect(m_socket, &QTcpSocket::connected, this, &MPDListen::onConnected);
    connect(m_socket, &QTcpSocket::readyRead, this, &MPDListen::onReadyRead);
    connect(m_socket, &QTcpSocket::disconnected, this, &MPDListen::onDisconnected);

    connect(m_reconnectTimer, &QTimer::timeout, this, [this]() {
        m_socket->connectToHost(m_host, m_port);
    });
}


// Set the Member Variables to given Local Variables and Connect
void MPDListen::start(const QString &host, quint16 port)
{
    m_host = host;
    m_port = port;
    m_socket->connectToHost(m_host, m_port);
}

// Upon Connection Establish, wait for Handshake to finish
void MPDListen::onConnected()
{
    m_gotGreeting = false;
    m_buffer.clear();
}


// Read Receivving data from Host:Port
void MPDListen::onReadyRead()
{
    m_buffer += m_socket->readAll();

    int newlineIndex;
    while ((newlineIndex = m_buffer.indexOf('\n')) != -1) {
        QByteArray line = m_buffer.left(newlineIndex);
        m_buffer.remove(0, newlineIndex + 1);
        processLine(line);
    }
}

// Process the Obtained Output
void MPDListen::processLine(const QByteArray &line)
{
    // Handle Handshake
    if (!m_gotGreeting) {
        m_gotGreeting = true;
        sendIdle();
        return;
    }

    // Idle Player Return, transaction not fully finished
    if (line.startsWith("changed: player")) {
        m_playerChangedPending = true;
        return;
    }

    // Idle Stored_Playlist Return, transaction not fully finished
    if (line.startsWith("changed: stored_playlist")) {
        m_playlistsChangedPending = true;
        return;
    }

    // TRANSACTION COMPLETE,  Emit Signal to QML, start running the listener again
    if (line == "OK") {

        // Player Changed
        if (m_playerChangedPending) {
            m_playerChangedPending = false;
            emit playerChanged();
        }

        // Playlists Changed
        if (m_playlistsChangedPending) {
            m_playlistsChangedPending = false;
            emit playlistsChanged();
        }

        sendIdle();
        return;
    }
}


// Send Socket the command to Wait and Listen for Player Events
void MPDListen::sendIdle()
{
    m_socket->write("idle player stored_playlist\n");
}

// Handle Disconnection
void MPDListen::onDisconnected()
{
    m_gotGreeting = false;
    m_buffer.clear();
    m_reconnectTimer->start();      // Attempt to reconnect to MPD
}
