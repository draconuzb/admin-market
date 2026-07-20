"""Order invoice (hisob-faktura) PDF rendering with reportlab."""

from __future__ import annotations

from decimal import Decimal
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

from app.models import Company, Order, User

_ACCENT = colors.HexColor("#2563EB")
_LIGHT = colors.HexColor("#EEF2FF")
_GREY = colors.HexColor("#6B7280")


def _money(v) -> str:
    d = Decimal(str(v or 0)).quantize(Decimal("0.01"))
    # 1 234 567.00 — space thousands separator, common in UZ.
    whole, frac = f"{d:.2f}".split(".")
    grouped = f"{int(whole):,}".replace(",", " ")
    return f"{grouped}.{frac}"


def render_invoice_pdf(order: Order, factory: Company | None, buyer: User | None) -> bytes:
    buf = BytesIO()
    doc = SimpleDocTemplate(
        buf, pagesize=A4,
        leftMargin=18 * mm, rightMargin=18 * mm,
        topMargin=16 * mm, bottomMargin=16 * mm,
        title=f"Hisob-faktura #{order.id}",
    )
    styles = getSampleStyleSheet()
    h = styles["Heading1"]; h.textColor = _ACCENT
    small = styles["Normal"]; small.fontSize = 9; small.textColor = _GREY
    normal = styles["Normal"]

    story = []
    story.append(Paragraph("Admin Market", h))
    story.append(Paragraph(f"Hisob-faktura #{order.id}", styles["Heading2"]))
    story.append(Paragraph(order.created_at.strftime("%d.%m.%Y %H:%M"), small))
    story.append(Spacer(1, 8 * mm))

    # Seller / buyer block.
    seller = factory.name if factory else "—"
    buyer_name = order.shipping_name or (buyer.full_name if buyer else "—")
    buyer_phone = order.shipping_phone or (buyer.phone if buyer else "—")
    info = Table(
        [
            [Paragraph("<b>Sotuvchi (zavod):</b>", normal), Paragraph("<b>Xaridor:</b>", normal)],
            [Paragraph(seller, normal), Paragraph(buyer_name, normal)],
            [Paragraph(factory.region or "" if factory else "", small),
             Paragraph(buyer_phone, small)],
            [Paragraph("", small),
             Paragraph(order.shipping_address or "", small)],
        ],
        colWidths=[85 * mm, 85 * mm],
    )
    info.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    story.append(info)
    story.append(Spacer(1, 6 * mm))

    # Line items.
    rows = [["#", "Mahsulot", "Narx", "Soni", "Jami"]]
    for i, it in enumerate(order.items, start=1):
        rows.append([
            str(i), it.product_name, _money(it.unit_price),
            str(it.quantity), _money(it.subtotal),
        ])
    table = Table(rows, colWidths=[10 * mm, 84 * mm, 28 * mm, 18 * mm, 30 * mm], repeatRows=1)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), _ACCENT),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("ALIGN", (2, 0), (-1, -1), "RIGHT"),
        ("ALIGN", (0, 0), (0, -1), "CENTER"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, _LIGHT]),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E5E7EB")),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    story.append(table)
    story.append(Spacer(1, 5 * mm))

    # Totals.
    totals = Table(
        [
            ["Jami summa:", _money(order.total_amount)],
            [f"Komissiya ({order.commission_percent}%):", _money(order.commission_amount)],
        ],
        colWidths=[140 * mm, 30 * mm],
    )
    totals.setStyle(TableStyle([
        ("ALIGN", (0, 0), (-1, -1), "RIGHT"),
        ("FONTSIZE", (0, 0), (-1, -1), 10),
        ("FONTNAME", (0, 0), (0, 0), "Helvetica-Bold"),
        ("TEXTCOLOR", (0, 0), (0, 0), _ACCENT),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
    ]))
    story.append(totals)
    story.append(Spacer(1, 10 * mm))
    story.append(Paragraph(
        "To'lov yetkazib berilganda naqd yoki kelishuv asosida amalga oshiriladi.", small))

    doc.build(story)
    return buf.getvalue()
