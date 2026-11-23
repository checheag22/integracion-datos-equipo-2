from pathlib import Path
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE, MSO_CONNECTOR
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "presentacion-final-equipo-2.pptx"
W, H = 13.333, 7.5

IVORY = "F6F1E8"
PAPER = "FFFCF7"
GREEN = "183D34"
GREEN2 = "2E594B"
BURGUNDY = "6C303A"
GOLD = "BE9856"
INK = "26312C"
MUTED = "6F726B"
PALE_GREEN = "E7EEE8"
PALE_GOLD = "F1E7D5"
WHITE = "FFFFFF"

prs = Presentation()
prs.slide_width = Inches(W)
prs.slide_height = Inches(H)
blank = prs.slide_layouts[6]


def color(hex_value):
    return RGBColor.from_string(hex_value)


def rect(slide, x, y, w, h, fill, radius=False, line=None, transparency=0):
    shape = slide.shapes.add_shape(
        MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE,
        Inches(x), Inches(y), Inches(w), Inches(h)
    )
    shape.fill.solid()
    shape.fill.fore_color.rgb = color(fill)
    if transparency:
        shape.fill.transparency = transparency
    if line:
        shape.line.color.rgb = color(line)
        shape.line.width = Pt(0.8)
    else:
        shape.line.fill.background()
    if radius:
        try:
            shape.adjustments[0] = 0.12
        except Exception:
            pass
    return shape


def text(slide, x, y, w, h, value, size=16, fill=INK, bold=False,
         font="Avenir Next", align=PP_ALIGN.LEFT, valign=MSO_ANCHOR.TOP,
         margin=0.02, italic=False, spacing=1.0):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.clear()
    tf.word_wrap = True
    tf.margin_left = Inches(margin)
    tf.margin_right = Inches(margin)
    tf.margin_top = Inches(margin)
    tf.margin_bottom = Inches(margin)
    tf.vertical_anchor = valign
    p = tf.paragraphs[0]
    p.alignment = align
    p.line_spacing = spacing
    run = p.add_run()
    run.text = value
    run.font.name = font
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color(fill)
    return box


def photo(slide, filename, x, y, w, h, focus=(0.5, 0.5)):
    path = ROOT / "assets" / filename
    pic = slide.shapes.add_picture(str(path), Inches(x), Inches(y), width=Inches(w), height=Inches(h))
    with Image.open(path) as im:
        sw, sh = im.size
    source_ar = sw / sh
    target_ar = w / h
    fx, fy = focus
    if source_ar > target_ar:
        crop = 1 - target_ar / source_ar
        pic.crop_left = crop * fx
        pic.crop_right = crop * (1 - fx)
    elif source_ar < target_ar:
        crop = 1 - source_ar / target_ar
        pic.crop_top = crop * fy
        pic.crop_bottom = crop * (1 - fy)
    return pic


def title(slide, eyebrow, heading, sub=None, dark=False):
    fg = WHITE if dark else INK
    accent = "D7B879" if dark else GOLD
    text(slide, 0.62, 0.34, 11.8, 0.26, eyebrow.upper(), 10, accent, True)
    text(slide, 0.62, 0.72, 12.0, 0.58, heading, 26, fg, True, font="Georgia")
    if sub:
        text(slide, 0.64, 1.35, 11.8, 0.38, sub, 13, "E3DDD1" if dark else MUTED)


def footer(slide, number, dark=False, label="INTEGRACIÓN DE DATOS · EQUIPO 2"):
    fg = "D6D1C7" if dark else MUTED
    text(slide, 0.62, 7.18, 9.5, 0.18, label, 8, fg, True)
    text(slide, 12.05, 7.13, 0.65, 0.22, f"{number:02d} / 08", 9, fg, True, align=PP_ALIGN.RIGHT)


def new_slide(bg=IVORY):
    slide = prs.slides.add_slide(blank)
    slide.background.fill.solid()
    slide.background.fill.fore_color.rgb = color(bg)
    return slide


def pill(slide, x, y, w, label, fill=PALE_GREEN, fg=GREEN):
    rect(slide, x, y, w, 0.33, fill, radius=True)
    text(slide, x + 0.1, y + 0.04, w - 0.2, 0.22, label, 9, fg, True, align=PP_ALIGN.CENTER)


# 1 — Portada y responsables
s = new_slide(GREEN)
photo(s, "portada-vinicola-golden-hour.png", 0, 0, 5.5, H, focus=(0.43, 0.5))
rect(s, 5.5, 0, W - 5.5, H, GREEN)
text(s, 6.12, 0.58, 6.45, 0.3, "PROYECTO FINAL · INTEGRACIÓN DE DATOS", 10, "D7B879", True)
logo = s.shapes.add_picture(str(ROOT / "assets" / "logo_conceptual-alba.png"), Inches(11.93), Inches(0.46), width=Inches(0.55), height=Inches(0.55))
text(s, 6.1, 1.18, 6.55, 1.28, "De datos dispersos\na una respuesta clara", 30, WHITE, True, font="Georgia", spacing=0.95)
text(s, 6.14, 2.58, 6.25, 0.62, "Ventas, clientes y calificaciones integrados en SQL Server.", 17, "F2EDE4")
pill(s, 6.14, 3.35, 2.75, "Viñedos del Alba · caso ficticio", fill="2B5548", fg=WHITE)
text(s, 6.14, 3.92, 6.0, 0.22, "EQUIPO 2 · RESPONSABILIDADES", 9, "D7B879", True)
roles = [
    ("Ezequiel Aguilera", "Liderazgo de proyecto"),
    ("José Hernández", "Arquitectura de datos"),
    ("Patricio García", "Ingeniería ETL"),
    ("Ximena Ibarra", "Calidad y QA"),
    ("Joel Ibarra", "BI + Documentación y Trello"),
]
for i, (name, role) in enumerate(roles):
    y = 4.25 + i * 0.4
    text(s, 6.15, y, 2.8, 0.27, name, 12, WHITE, True)
    text(s, 9.0, y, 3.45, 0.27, role, 11, "E5DED2")
text(s, 6.14, 6.55, 6.2, 0.32, "Exposición + demo: 12–15 min   ·   Preguntas: 6–8 min", 10, "E3DDD1")
footer(s, 1, dark=True)

# 2 — Fuentes y alcance
s = new_slide()
title(s, "01 · Fuentes y arquitectura", "Tres fuentes, una misma historia", "Caso académico de vinícola; la muestra disponible se carga desde scripts SQL.")
cards = [
    ("fuente-punto-venta.png", "VENTAS POS", "5 transacciones", "Qué se vendió y cuánto." , (0.55,0.5)),
    ("clientes-vinicola.png", "CLIENTES CRM", "4 clientes", "Quién compra y su membresía.", (0.72,0.5)),
    ("flujo-medallon-fotografico.png", "RATINGS", "3 vinos", "Cómo se califica cada etiqueta.", (0.5,0.5)),
]
for i, (img, label, stat, desc, focus) in enumerate(cards):
    x = 0.62 + i * 4.08
    rect(s, x, 2.0, 3.83, 3.62, PAPER, radius=True, line="E7DFD2")
    photo(s, img, x + 0.12, 2.12, 3.59, 1.82, focus=focus)
    text(s, x + 0.22, 4.12, 3.35, 0.25, label, 10, BURGUNDY, True)
    text(s, x + 0.22, 4.49, 3.35, 0.44, stat, 20, GREEN, True, font="Georgia")
    text(s, x + 0.22, 5.01, 3.36, 0.42, desc, 12, MUTED)
rect(s, 0.62, 5.92, 12.08, 0.72, PALE_GOLD, radius=True)
text(s, 0.83, 6.08, 11.65, 0.38, "Alcance real: POS + CRM + ratings. No recibimos archivos fuente originales ni datos de inventario o ventas web.", 12, INK, True, valign=MSO_ANCHOR.MIDDLE)
footer(s, 2)

# 3 — Modelo y relaciones
s = new_slide()
title(s, "02 · Modelo relacional", "Una venta conecta cliente y vino", "Las llaves mantienen la relación y evitan ventas huérfanas en Oro.")
# bronze source cards
source_cards = [(0.72, "Bronce · POS", "texto crudo"), (4.95, "Bronce · CRM", "texto crudo"), (9.17, "Bronce · ratings", "texto crudo")]
for x, heading, caption in source_cards:
    rect(s, x, 1.98, 3.42, 0.69, PAPER, radius=True, line="E1D8CA")
    text(s, x + 0.16, 2.09, 3.1, 0.25, heading, 12, BURGUNDY, True)
    text(s, x + 0.16, 2.37, 3.1, 0.18, caption, 9, MUTED)
# La fuente de ventas llega al hecho; CRM y ratings nutren sus dimensiones.
for x1, y1, x2, y2 in [(6.66,2.67,3.25,3.35),(10.88,2.67,10.05,3.35)]:
    ln = s.shapes.add_connector(MSO_CONNECTOR.STRAIGHT, Inches(x1), Inches(y1), Inches(x2), Inches(y2))
    ln.line.color.rgb = color(GOLD)
    ln.line.width = Pt(1.4)
# dimension cards
rect(s, 1.15, 3.35, 4.25, 1.55, PALE_GREEN, radius=True)
text(s, 1.42, 3.56, 3.75, 0.28, "plata.Dim_Clientes", 15, GREEN, True, font="Georgia")
text(s, 1.42, 4.0, 3.72, 0.68, "PK  ID_Cliente  VARCHAR(30)\nNombre · membresía · ciudad · gasto", 11, INK)
rect(s, 7.93, 3.35, 4.25, 1.55, PALE_GOLD, radius=True)
text(s, 8.2, 3.56, 3.75, 0.28, "plata.Dim_Vinos", 15, BURGUNDY, True, font="Georgia")
text(s, 8.2, 4.0, 3.72, 0.68, "PK  SKU_Vino  VARCHAR(30)\nEtiqueta · puntaje · cepa y origen", 11, INK)
# central fact
rect(s, 3.7, 5.49, 5.95, 1.06, GREEN, radius=True)
text(s, 4.0, 5.65, 5.45, 0.26, "oro.Fact_Ventas_POS", 16, WHITE, True, font="Georgia", align=PP_ALIGN.CENTER)
text(s, 4.0, 6.03, 5.45, 0.25, "PK ID_Venta_POS · FK cliente y vino · fecha DATETIME2 · precio DECIMAL", 10, "EDE8DE", align=PP_ALIGN.CENTER)
# relationship connectors
for x1, y1, x2, y2 in [(3.25,4.9,5.0,5.49),(10.05,4.9,8.35,5.49)]:
    ln = s.shapes.add_connector(MSO_CONNECTOR.STRAIGHT, Inches(x1), Inches(y1), Inches(x2), Inches(y2))
    ln.line.color.rgb = color(GOLD)
    ln.line.width = Pt(2)
text(s, 0.77, 6.72, 11.85, 0.23, "Customer 360 (Tickets, Interacciones y Ventas) no forma parte del esquema implementado.", 10, MUTED, italic=True)
footer(s, 3)

# 4 — Demo guiada
s = new_slide(GREEN)
photo(s, "insight-de-negocio.png", 7.15, 0, W - 7.15, H, focus=(0.72,0.5))
rect(s, 0, 0, 7.2, H, GREEN)
title(s, "03 · Corrida en vivo · 2–3 min", "Tres acciones; un resultado", "Patricio · mostrar qué cambia, no leer el código.", dark=True)
steps = [
    ("01", "Cargar las capas", "Ejecutar los scripts 01 → 04 en orden."),
    ("02", "Revisar la calidad", "Abrir oro.vw_Calidad_Integracion."),
    ("03", "Responder una pregunta", "Consultar ventas y el historial de CLI-V01."),
]
for i, (num, head, desc) in enumerate(steps):
    y = 2.03 + i * 1.12
    rect(s, 0.66, y, 0.56, 0.56, GOLD, radius=True)
    text(s, 0.66, y + 0.09, 0.56, 0.32, num, 14, GREEN, True, align=PP_ALIGN.CENTER)
    text(s, 1.48, y - 0.01, 5.25, 0.31, head, 16, WHITE, True)
    text(s, 1.49, y + 0.38, 5.25, 0.42, desc, 12, "E4DED2")
rect(s, 0.66, 5.56, 5.96, 0.86, "294D43", radius=True)
text(s, 0.87, 5.7, 5.55, 0.52, "Pregunta que contesta la demo: ¿qué compró este cliente y qué calidad tiene ese vino?", 12, WHITE, True, valign=MSO_ANCHOR.MIDDLE)
rect(s, 7.65, 6.25, 5.1, 0.58, GREEN, radius=True)
text(s, 7.85, 6.37, 4.7, 0.31, "Ejemplo: CLI-V01 · 1–3 ago 2026", 12, WHITE, True, align=PP_ALIGN.CENTER)
footer(s, 4, dark=True)

# 5 — Transformación legible
s = new_slide()
title(s, "04 · Limpieza e idempotencia", "Limpiar sin perder el origen", "Cada regla resuelve un problema concreto y conserva la trazabilidad.")
photo(s, "flujo-medallon-fotografico.png", 0.62, 1.9, 5.12, 4.75, focus=(0.49,0.5))
rect(s, 0.62, 5.86, 5.12, 0.79, GREEN, radius=True, transparency=8)
text(s, 0.86, 6.02, 4.65, 0.41, "Bronce conserva → Plata limpia → Oro responde", 13, WHITE, True, align=PP_ALIGN.CENTER, valign=MSO_ANCHOR.MIDDLE)
etl = [
    ("1", "Conservar", "Bronce guarda el valor original como texto."),
    ("2", "Estandarizar", "TRIM y UPPER normalizan; TRY_CONVERT y COALESCE aplican reglas."),
    ("3", "Elegir una versión", "ROW_NUMBER prioriza fecha y desempata por ingesta."),
    ("4", "Integrar", "LEFT JOIN conserva venta anónima; FK valida relaciones."),
]
for i, (n, head, desc) in enumerate(etl):
    y = 1.95 + i * 0.97
    rect(s, 6.12, y, 0.48, 0.48, PALE_GOLD, radius=True)
    text(s, 6.12, y + 0.08, 0.48, 0.28, n, 13, BURGUNDY, True, align=PP_ALIGN.CENTER)
    text(s, 6.82, y - 0.01, 5.82, 0.3, head, 15, INK, True)
    text(s, 6.82, y + 0.35, 5.82, 0.43, desc, 11, MUTED)
rect(s, 6.12, 5.98, 6.28, 0.68, PALE_GREEN, radius=True)
text(s, 6.33, 6.06, 5.88, 0.53, "‘ Gold ’ → ‘GOLD’ · $4,920 marcado como proxy.\nReejecutar conserva una venta por llave en Oro.", 10, GREEN, True, valign=MSO_ANCHOR.MIDDLE)
footer(s, 5)

# 6 — Calidad y límites
s = new_slide()
title(s, "05 · Calidad", "¿Qué tan confiable es esta muestra?", "Respondemos con conteos observados, no con suposiciones.")
metrics = [
    ("5 / 5", "ventas integradas", "Todas las ventas POS válidas."),
    ("0", "ventas rechazadas", "Sin conversiones inválidas en la muestra."),
    ("1", "venta anónima", "Se conserva como CLI-MOSTRADOR."),
    ("$4,920", "proxy identificado", "Imputación CRM, no gasto anual confirmado."),
]
for i, (value, label, note) in enumerate(metrics):
    col, row = i % 2, i // 2
    x, y = 0.65 + col * 4.1, 2.05 + row * 1.78
    rect(s, x, y, 3.82, 1.5, PAPER, radius=True, line="E8DFD3")
    text(s, x + 0.2, y + 0.15, 3.4, 0.53, value, 25, GREEN if i != 3 else BURGUNDY, True, font="Georgia")
    text(s, x + 0.22, y + 0.73, 3.35, 0.25, label, 12, INK, True)
    text(s, x + 0.22, y + 1.03, 3.36, 0.35, note, 10, MUTED)
photo(s, "clientes-vinicola.png", 8.95, 2.05, 3.72, 3.25, focus=(0.75,0.5))
text(s, 0.72, 5.63, 7.92, 0.64, "CRM: 4/4 · ratings: 3/3 · 0 duplicados en la muestra · 0 clientes/vinos huérfanos. CHECK: puntaje, botellas y precio.", 10, MUTED, True, valign=MSO_ANCHOR.MIDDLE)
rect(s, 8.95, 5.46, 3.72, 1.02, PALE_GOLD, radius=True)
text(s, 9.15, 5.59, 3.32, 0.69, "Límite: solo cinco ventas. Sin inventario ni datos web no podemos recomendar reabasto ni medir venta en línea.", 11, INK, True, valign=MSO_ANCHOR.MIDDLE)
footer(s, 6)

# 7 — Insight de negocio
s = new_slide()
photo(s, "insight-de-negocio.png", 0, 0, 5.55, H, focus=(0.68,0.5))
rect(s, 5.55, 0, W - 5.55, H, IVORY)
text(s, 6.12, 0.48, 6.45, 0.24, "06 · ORO Y DECISIÓN DE NEGOCIO", 10, BURGUNDY, True)
text(s, 6.1, 0.88, 6.4, 0.65, "Una señal para probar", 27, INK, True, font="Georgia")
text(s, 6.12, 1.65, 6.0, 0.31, "Así se ven los resultados de la muestra", 13, MUTED)
for i,(num,label) in enumerate([("$22,760","5 ventas · 24 botellas"),("63.3%","Rioja: $14,400"),("12 / 15","Platinum >93 (80%) · 1 cliente")]):
    y=2.18+i*0.87
    text(s,6.15,y,2.45,0.48,num,23,GREEN if i!=1 else BURGUNDY,True,font="Georgia")
    text(s,8.77,y+0.08,3.75,0.37,label,12,INK,True)
rect(s,6.1,4.78,6.3,1.38,PALE_GOLD,radius=True)
text(s,6.35,4.91,5.82,1.12,"Rioja: $14,400 (63.27%). Los $14,400 de vinos >93 son 12 botellas de Tempranillo Rioja (93.8) compradas por una persona. Es una hipótesis para probar, no causalidad demostrada.",11,INK,True,valign=MSO_ANCHOR.MIDDLE)
text(s,6.12,6.43,6.1,0.33,"Joel · lectura de Oro · Ezequiel · decisión comercial",10,MUTED,italic=True)
footer(s, 7)

# 8 — Repositorio y cierre
s = new_slide(GREEN)
photo(s, "portada-vinicola-golden-hour.png", 7.35, 0, W - 7.35, H, focus=(0.67,0.52))
rect(s, 0, 0, 7.38, H, GREEN)
title(s, "07 · GitHub y Trello", "El proyecto queda listo para continuar", "Joel · enseñar el repositorio y el tablero, sin leer cada archivo.", dark=True)
rect(s,0.65,2.0,6.05,1.15,"294D43",radius=True)
text(s,0.9,2.16,5.6,0.29,"GITHUB · RAMA DE ENTREGA",10,"D7B879",True)
text(s,0.9,2.54,5.58,0.34,"SQL modular · documentación · presentación",13,WHITE,True)
rect(s,0.65,3.42,6.05,1.15,"294D43",radius=True)
text(s,0.9,3.58,5.6,0.29,"TRELLO · TABLERO PRIVADO",10,"D7B879",True)
text(s,0.9,3.96,5.58,0.34,"Avance completado + tareas de defensa",13,WHITE,True)
text(s,0.72,4.95,5.8,0.26,"SIGUE ANTES DE ENTREGAR",10,"D7B879",True)
for i, item in enumerate(["Ensayar la demo y preparar capturas reales de SSMS", "Definir Customer 360 y documentar sus campos", "Subir el PDF a Moodle cuando corresponda"]):
    y = 5.33 + i * 0.41
    text(s, 0.76, y, 0.25, 0.25, "•", 16, GOLD, True)
    text(s, 1.06, y, 5.35, 0.28, item, 11, WHITE)
rect(s,7.68,5.57,5.15,1.2,GREEN,radius=True)
text(s,7.92,5.75,4.68,0.82,"Cierre: integrar los datos nos deja hacer una mejor pregunta; la siguiente mejora empieza por conseguir fuentes y más muestra.",13,WHITE,True,font="Georgia",align=PP_ALIGN.CENTER,valign=MSO_ANCHOR.MIDDLE)
footer(s, 8, dark=True)

prs.save(OUT)
print(OUT)
