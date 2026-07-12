// Heavily Commented because I struggle at C++ stuff, did this purely cuz couldn't find alternate way that worked properly. Code might be ineffecient, or too complex, apologies

// .h Files are Headers which declare the Objects and all the properties and methods within

/*
 * Purpose: To detect changes in the MPD data directly without relying on USER input
 * As,
 *  1) Polling is ineffecient, wastes CPU Cycles
 *  2) mpc idleloop fails in DataSource, and idle leaves Blindspot time range
 *
 * Direct Connection to MPD to Singal on desired Changes to QML directly so rightful Data can be updated
 * Current uses: Player & stored_playlist
 *              [Current Song play status change, and changes to playlists]
 */

#pragma once                // In Case same Header is used in multiple files, avoid compiling it multiple times

#include <QObject>          // Adds MOC, which allows for stuff like Signalling, parent-child, etc.
#include <QQmlEngine>       // Allows the CPP Code to be exposed to QML
#include <QTcpSocket>       // TCP Socket to reach out to MPD
#include <QTimer>           // Timer data type used for Timing, same in function of QML Timer
#include <QByteArray>       // QT C++ Data Type Holding raw uncoded bytes

// MAIN Class
class MPDListen : public QObject
{
    Q_OBJECT                // Allow MOC for this Class
    QML_ELEMENT             // Expose to QML


    public:
        explicit MPDListen(QObject *parent = nullptr);

        // Q_INVOKABLE: Callable from QML, Does the Handshake with MDP. &host passes the value straight down and not a Copy
        Q_INVOKABLE void start(const QString &host = QStringLiteral("127.0.0.1"), quint16 port = 6600);


    signals:
        // The Signal QML Reacts to
        void playerChanged();
        void playlistsChanged();


    private slots:
        // Slots are Methods Wired to Signals
        void onConnected();                 // Upon Succesful TCP handshake
        void onReadyRead();                 // Upon Receiving Data from the TCP connection
        void onDisconnected();              // Upon Disconnection [MPD Crash or another issue]


    private:
        void sendIdle();                            // Send the main command "idle player stored_playlist" to the MPD TCP
        void processLine(const QByteArray &line);   // Handle data returned from the Socket


        QTcpSocket *m_socket;                       // The Socket
        QTimer *m_reconnectTimer;                   // Timer to restablish connection if disconnection happens
        QByteArray m_buffer;                        // Data is returned in stream, buffer holds the data until it's finished'


        QString m_host;                             // Host IP
        quint16 m_port = 6600;                      // Host Port, Hardfixed due to MPC usually residing at such, still changeable at start


        bool m_gotGreeting = false;                 // Whether the Socket handshake is done
        bool m_playerChangedPending = false;        // Whether in the process of Receiving Player Change Data [not byte stream, whether transaction is complete]
        bool m_playlistsChangedPending = false;      // Whether in the process of Receiving Playlist Change Data
};
