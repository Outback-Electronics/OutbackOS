#include "TerminalView.h"

#include <QFontMetricsF>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QPainter>

#include <utility>

TerminalView::TerminalView(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    m_font = QFont(QStringLiteral("monospace"));
    m_font.setPointSize(11);
    m_font.setStyleHint(QFont::Monospace);

    setFlag(QQuickItem::ItemIsFocusScope);
    setAcceptedMouseButtons(Qt::LeftButton);
}

TerminalView::~TerminalView()
{
    if (m_vterm) {
        vterm_free(m_vterm);
    }
}

void TerminalView::start()
{
    if (m_vterm) {
        return;
    }

    const QFontMetricsF metrics(m_font);
    m_cellWidth = metrics.horizontalAdvance(QLatin1Char('M'));
    m_cellHeight = metrics.height();

    m_cols = qMax(1, static_cast<int>(width() / m_cellWidth));
    m_rows = qMax(1, static_cast<int>(height() / m_cellHeight));

    m_vterm = vterm_new(m_rows, m_cols);
    vterm_set_utf8(m_vterm, 1);
    vterm_output_set_callback(m_vterm, &TerminalView::outputCallback, this);

    m_screen = vterm_obtain_screen(m_vterm);
    vterm_screen_reset(m_screen, 1);

    static const VTermScreenCallbacks callbacks = {
        &TerminalView::damageCallback,
        nullptr,
        &TerminalView::moveCursorCallback,
        nullptr,
        nullptr,
        &TerminalView::resizeCallback,
        nullptr,
        nullptr,
        nullptr
    };

    vterm_screen_set_callbacks(m_screen, &callbacks, this);

    m_pty = new PtySession(this);

    connect(
        m_pty,
        &PtySession::dataReceived,
        this,
        &TerminalView::handlePtyData
    );

    m_pty->start(m_cols, m_rows);
}

void TerminalView::handlePtyData(const QByteArray &data)
{
    vterm_input_write(m_vterm, data.constData(), static_cast<size_t>(data.size()));
    vterm_screen_flush_damage(m_screen);
}

void TerminalView::recomputeGrid()
{
    if (!m_vterm) {
        return;
    }

    const int newCols = qMax(1, static_cast<int>(width() / m_cellWidth));
    const int newRows = qMax(1, static_cast<int>(height() / m_cellHeight));

    if (newCols == m_cols && newRows == m_rows) {
        return;
    }

    m_cols = newCols;
    m_rows = newRows;

    vterm_set_size(m_vterm, m_rows, m_cols);
    m_pty->resize(m_cols, m_rows);

    update();
}

void TerminalView::geometryChange(
    const QRectF &newGeometry,
    const QRectF &oldGeometry
)
{
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    recomputeGrid();
}

void TerminalView::paint(QPainter *painter)
{
    if (!m_screen) {
        return;
    }

    const QColor backgroundColour("#0D1115");

    painter->fillRect(boundingRect(), backgroundColour);
    painter->setFont(m_font);

    for (int row = 0; row < m_rows; ++row) {
        for (int col = 0; col < m_cols; ++col) {
            VTermPos pos{row, col};
            VTermScreenCell cell;

            if (!vterm_screen_get_cell(m_screen, pos, &cell)) {
                continue;
            }

            vterm_screen_convert_color_to_rgb(m_screen, &cell.fg);
            vterm_screen_convert_color_to_rgb(m_screen, &cell.bg);

            QColor fg(cell.fg.rgb.red, cell.fg.rgb.green, cell.fg.rgb.blue);
            QColor bg(cell.bg.rgb.red, cell.bg.rgb.green, cell.bg.rgb.blue);

            if (cell.attrs.reverse) {
                std::swap(fg, bg);
            }

            const QRectF cellRect(
                col * m_cellWidth,
                row * m_cellHeight,
                m_cellWidth,
                m_cellHeight
            );

            if (bg != backgroundColour) {
                painter->fillRect(cellRect, bg);
            }

            int charCount = 0;
            while (
                charCount < VTERM_MAX_CHARS_PER_CELL
                && cell.chars[charCount] != 0
            ) {
                ++charCount;
            }

            if (charCount > 0) {
                const QString text = QString::fromUcs4(
                    reinterpret_cast<const char32_t *>(cell.chars),
                    charCount
                );

                QFont cellFont = m_font;
                cellFont.setBold(cell.attrs.bold);
                painter->setFont(cellFont);

                painter->setPen(fg);
                painter->drawText(
                    cellRect,
                    Qt::AlignVCenter | Qt::AlignLeft,
                    text
                );
            }
        }
    }

    if (m_cursorVisible) {
        const QRectF cursorRect(
            m_cursorPos.col * m_cellWidth,
            m_cursorPos.row * m_cellHeight,
            m_cellWidth,
            m_cellHeight
        );

        painter->fillRect(cursorRect, QColor(217, 115, 47, 140));
    }
}

void TerminalView::keyPressEvent(QKeyEvent *event)
{
    if (!m_vterm) {
        event->ignore();
        return;
    }

    int mod = VTERM_MOD_NONE;

    if (event->modifiers() & Qt::ShiftModifier) {
        mod |= VTERM_MOD_SHIFT;
    }

    if (event->modifiers() & Qt::AltModifier) {
        mod |= VTERM_MOD_ALT;
    }

    if (event->modifiers() & Qt::ControlModifier) {
        mod |= VTERM_MOD_CTRL;
    }

    const auto modifier = static_cast<VTermModifier>(mod);

    switch (event->key()) {
        case Qt::Key_Return:
        case Qt::Key_Enter:
            vterm_keyboard_key(m_vterm, VTERM_KEY_ENTER, modifier);
            break;
        case Qt::Key_Backspace:
            vterm_keyboard_key(m_vterm, VTERM_KEY_BACKSPACE, modifier);
            break;
        case Qt::Key_Tab:
            vterm_keyboard_key(m_vterm, VTERM_KEY_TAB, modifier);
            break;
        case Qt::Key_Escape:
            vterm_keyboard_key(m_vterm, VTERM_KEY_ESCAPE, modifier);
            break;
        case Qt::Key_Up:
            vterm_keyboard_key(m_vterm, VTERM_KEY_UP, modifier);
            break;
        case Qt::Key_Down:
            vterm_keyboard_key(m_vterm, VTERM_KEY_DOWN, modifier);
            break;
        case Qt::Key_Left:
            vterm_keyboard_key(m_vterm, VTERM_KEY_LEFT, modifier);
            break;
        case Qt::Key_Right:
            vterm_keyboard_key(m_vterm, VTERM_KEY_RIGHT, modifier);
            break;
        case Qt::Key_Home:
            vterm_keyboard_key(m_vterm, VTERM_KEY_HOME, modifier);
            break;
        case Qt::Key_End:
            vterm_keyboard_key(m_vterm, VTERM_KEY_END, modifier);
            break;
        case Qt::Key_PageUp:
            vterm_keyboard_key(m_vterm, VTERM_KEY_PAGEUP, modifier);
            break;
        case Qt::Key_PageDown:
            vterm_keyboard_key(m_vterm, VTERM_KEY_PAGEDOWN, modifier);
            break;
        case Qt::Key_Delete:
            vterm_keyboard_key(m_vterm, VTERM_KEY_DEL, modifier);
            break;
        default: {
            const QString text = event->text();

            if (text.isEmpty()) {
                event->ignore();
                return;
            }

            vterm_keyboard_unichar(
                m_vterm,
                text.at(0).unicode(),
                modifier
            );
        }
    }

    event->accept();
}

void TerminalView::mousePressEvent(QMouseEvent *event)
{
    forceActiveFocus();
    event->accept();
}

void TerminalView::outputCallback(const char *s, size_t len, void *user)
{
    auto *self = static_cast<TerminalView *>(user);

    if (self->m_pty) {
        self->m_pty->write(QByteArray(s, static_cast<int>(len)));
    }
}

int TerminalView::damageCallback(VTermRect rect, void *user)
{
    Q_UNUSED(rect)

    static_cast<TerminalView *>(user)->update();
    return 1;
}

int TerminalView::moveCursorCallback(
    VTermPos pos,
    VTermPos oldPos,
    int visible,
    void *user
)
{
    Q_UNUSED(oldPos)

    auto *self = static_cast<TerminalView *>(user);
    self->m_cursorPos = pos;
    self->m_cursorVisible = visible != 0;
    self->update();

    return 1;
}

int TerminalView::resizeCallback(int rows, int cols, void *user)
{
    Q_UNUSED(rows)
    Q_UNUSED(cols)
    Q_UNUSED(user)

    return 1;
}
