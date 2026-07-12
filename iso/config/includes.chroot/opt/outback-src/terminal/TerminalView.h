#pragma once

#include <QFont>
#include <QQuickPaintedItem>

#include "PtySession.h"

extern "C" {
#include <vterm.h>
}

class TerminalView : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit TerminalView(QQuickItem *parent = nullptr);
    ~TerminalView() override;

    void paint(QPainter *painter) override;

    Q_INVOKABLE void start();

protected:
    void geometryChange(
        const QRectF &newGeometry,
        const QRectF &oldGeometry
    ) override;

    void keyPressEvent(QKeyEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;

private:
    void handlePtyData(const QByteArray &data);
    void recomputeGrid();

    static void outputCallback(const char *s, size_t len, void *user);
    static int damageCallback(VTermRect rect, void *user);
    static int moveCursorCallback(
        VTermPos pos,
        VTermPos oldPos,
        int visible,
        void *user
    );
    static int resizeCallback(int rows, int cols, void *user);

    PtySession *m_pty = nullptr;
    VTerm *m_vterm = nullptr;
    VTermScreen *m_screen = nullptr;

    int m_rows = 24;
    int m_cols = 80;
    qreal m_cellWidth = 8;
    qreal m_cellHeight = 16;

    VTermPos m_cursorPos{0, 0};
    bool m_cursorVisible = true;

    QFont m_font;
};
