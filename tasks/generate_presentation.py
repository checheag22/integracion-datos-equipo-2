from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_CONNECTOR, MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
OUT = ROOT / "docs" / "presentacion-final-equipo-2.pptx"
W, H = 13.333, 7.5

IVORY, PAPER = "F6F1E8", "FFFCF7"
GREEN, GREEN2 = "183D34", "2E594B"
BURGUNDY, GOLD = "6C303A", "BE9856"
INK, MUTED = "26312C", "6F726B"
PALE_GREEN, PALE_GOLD, WHITE = "E7EEE8", "F1E7D5", "FFFFFF"


def rgb(value):
    return RGBColor.from_string(value)


def font(size, bold=False):
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def make_medallion_asset():
    """Produce the required editable-delivery diagram from verified project facts."""
    width, height = 1800, 900
    im = Image.new("RGB", (width, height), "#F6F1E8")
    d = ImageDraw.Draw(im)
    colors = ["#8A3642", "#B58B45", "#28564A"]
    headings = ["BRONCE", "PLATA", "ORO"]
    titles = ["Entrada conservada", "Reglas y relaciones", "Consulta para decidir"]
    details = [
        ["7 ventas POS en Bronce", "4 ratings; uno fuera de escala", "Dos ejemplos POS sintéticos", "Texto crudo y trazable"],
        ["TRIM · UPPER · TRY_CONVERT", "ROW_NUMBER por llave natural", "Dim_Clientes · Dim_Vinos", "Validación de rangos y llaves"],
        ["Fact_Ventas_POS", "5 vistas de calidad y BI", "5 ventas · 24 botellas", "$22,760 MXN observados"],
    ]
    boxes = [(82, 135, 540, 700), (630, 135, 1090, 700), (1154, 135, 1718, 700)]
    for idx, (x1, y1, x2, y2) in enumerate(boxes):
        d.rounded_rectangle((x1, y1, x2, y2), radius=28, fill="#FFFCF7", outline="#E2D9CC", width=3)
        d.rounded_rectangle((x1, y1, x2, y1 + 86), radius=28, fill=colors[idx])
        d.rectangle((x1, y1 + 54, x2, y1 + 86), fill=colors[idx])
        d.text((x1 + 30, y1 + 18), headings[idx], font=font(33, True), fill="#FFFFFF")
        d.text((x1 + 28, y1 + 119), titles[idx], font=font(25, True), fill="#26312C")
        for row, item in enumerate(details[idx]):
            y = y1 + 190 + row * 73
            d.ellipse((x1 + 32, y + 7, x1 + 48, y + 23), fill=colors[idx])
            d.text((x1 + 62, y), item, font=font(19), fill="#3E423D")
        d.rounded_rectangle((x1 + 28, y2 - 60, x2 - 28, y2 - 22), radius=16, fill="#F1E7D5")
        d.text((x1 + 45, y2 - 56), ["Conservar", "Limpiar", "Responder"][idx], font=font(19, True), fill="#6C303A")
    for x in (560, 1090):
        d.line((x, 466, x + 48, 466), fill="#BE9856", width=8)
        d.polygon([(x + 48, 449), (x + 78, 466), (x + 48, 483)], fill="#BE9856")
    d.text((82, 780), "Alcance: muestra de SQL; sin archivos originales, inventario ni órdenes web.", font=font(22, True), fill="#26312C")
    im.save(ASSETS / "flujo_medallon_sql.png", optimize=True)


def make_sqlserver_evidence_crop():
    """Crop the actual Terminal capture for legibility; retain the full capture in docs/."""
    source = ROOT / "docs" / "captura-sqlserver-demo-2026-11-23.png"
    if not source.exists():
        raise FileNotFoundError(f"Falta evidencia real de SQL Server: {source}")
    with Image.open(source) as im:
        im.crop((0, 1278, 900, 1584)).save(ASSETS / "sqlserver_resultados.png", optimize=True)


def add_rect(slide, x, y, w, h, fill, radius=True, line=None, transparency=0):
    shape = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE,
                                   Inches(x), Inches(y), Inches(w), Inches(h))
    shape.fill.solid()
    shape.fill.fore_color.rgb = rgb(fill)
    if transparency:
        shape.fill.transparency = transparency
    if line:
        shape.line.color.rgb = rgb(line)
        shape.line.width = Pt(0.8)
    else:
        shape.line.fill.background()
    if radius:
        try:
            shape.adjustments[0] = 0.11
        except Exception:
            pass
    return shape


def add_text(slide, x, y, w, h, value, size=16, fill=INK, bold=False,
             face="Avenir Next", align=PP_ALIGN.LEFT, valign=MSO_ANCHOR.TOP,
             margin=0.03, italic=False):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.clear()
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = Inches(margin)
    tf.margin_top = tf.margin_bottom = Inches(margin)
    tf.vertical_anchor = valign
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = value
    run.font.name = face
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = rgb(fill)
    return box


def add_photo(slide, filename, x, y, w, h, focus=(0.5, 0.5)):
    path = ASSETS / filename
    pic = slide.shapes.add_picture(str(path), Inches(x), Inches(y), width=Inches(w), height=Inches(h))
    with Image.open(path) as im:
        sw, sh = im.size
    source_ar, target_ar = sw / sh, w / h
    fx, fy = focus
    if source_ar > target_ar:
        crop = 1 - target_ar / source_ar
        pic.crop_left, pic.crop_right = crop * fx, crop * (1 - fx)
    elif source_ar < target_ar:
        crop = 1 - source_ar / target_ar
        pic.crop_top, pic.crop_bottom = crop * fy, crop * (1 - fy)
    return pic


def new_slide(prs, bg=IVORY):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    slide.background.fill.solid()
    slide.background.fill.fore_color.rgb = rgb(bg)
    return slide


def heading(slide, eyebrow, title, subtitle=None, dark=False):
    fg = WHITE if dark else INK
    accent = "D7B879" if dark else BURGUNDY
    add_text(slide, 0.62, 0.35, 12, 0.25, eyebrow.upper(), 10, accent, True)
    add_text(slide, 0.62, 0.72, 12, 0.58, title, 27, fg, True, face="Georgia")
    if subtitle:
        add_text(slide, 0.64, 1.36, 11.9, 0.38, subtitle, 13, "E4DED2" if dark else MUTED)


def footer(slide, n, total):
    add_text(slide, 0.62, 7.16, 10, 0.18, "INTEGRACIÓN DE DATOS · EQUIPO 2", 8, MUTED, True)
    add_text(slide, 11.9, 7.13, 0.78, 0.22, f"{n:02d} / {total:02d}", 9, MUTED, True, align=PP_ALIGN.RIGHT)


def note(slide, minutes, script, cue):
    slide.notes_slide.notes_text_frame.text = (
        f"TIEMPO: {minutes} min\n\nQUÉ DECIR\n{script}\n\nIDEA PARA RECORDAR\n{cue}"
    )


make_medallion_asset()
make_sqlserver_evidence_crop()
prs = Presentation()
prs.slide_width, prs.slide_height = Inches(W), Inches(H)
blank = prs.slide_layouts[6]
total = 13

# 1 · Una portada fácil de abrir y explicar.
s = new_slide(prs, GREEN)
add_photo(s, "portada-vinicola-golden-hour.png", 0, 0, 5.15, H, focus=(0.43, 0.5))
add_rect(s, 5.15, 0, W - 5.15, H, GREEN, radius=False)
add_photo(s, "logo_negocio.png", 11.95, 0.45, 0.7, 0.82)
add_text(s, 5.8, 0.62, 5.6, 0.25, "PROYECTO INTEGRADOR · SQL SERVER", 10, "D7B879", True)
add_text(s, 5.8, 1.24, 6.5, 1.35, "De cada registro\na una venta confiable", 31, WHITE, True, face="Georgia")
add_text(s, 5.85, 2.86, 6.35, 0.62, "Integramos ventas, clientes y calificaciones para entender qué se vende y a quién.", 17, "F2EDE4")
add_rect(s, 5.85, 3.7, 3.42, 0.42, "2B5548")
add_text(s, 5.95, 3.78, 3.22, 0.22, "VIÑEDOS DEL ALBA · CASO FICTICIO", 9, WHITE, True, align=PP_ALIGN.CENTER)
add_text(s, 5.86, 4.42, 6.15, 0.55, "Ezequiel · José · Patricio · Ximena · Joel\nEquipo 2 · Universidad Iberoamericana León", 13, WHITE, True)
add_text(s, 5.86, 5.34, 6.22, 0.47, "15 min exposición y demo  +  8 min preguntas\n2 min de transiciones  =  25 min totales", 12, "E5DED2", True)
add_text(s, 0.62, 7.16, 4.0, 0.18, "INTEGRACIÓN DE DATOS · EQUIPO 2", 8, WHITE, True)
add_text(s, 11.9, 7.13, 0.78, 0.22, "01 / 13", 9, WHITE, True, align=PP_ALIGN.RIGHT)
note(s, 0.5, "Somos el Equipo 2. En quince minutos explicaremos el alcance, cómo fluyen los datos, qué controles usamos y qué resultado de negocio podemos defender. Después dejamos ocho minutos para las dos preguntas de cada integrante. El nombre Viñedos del Alba es ficticio y solo identifica el caso.", "Tres fuentes, tres capas, un caso académico.")

# 2 · Matriz de roles exigida por la guía.
s = new_slide(prs)
heading(s, "EQUIPO 2 · RESPONSABILIDADES", "Cada integrante tiene una parte clara", "Los cinco nombres y roles siguen el banco oficial de evaluación.")
roles = [
    ("Ezequiel Aguilera", "Líder de proyecto + BI", "Coordina y explica la decisión."),
    ("José Hernández", "Arquitecto de datos / SQL", "Explica capas, llaves y modelo."),
    ("Patricio García", "Ingeniero ETL / Pipeline", "Muestra ingesta y transformación."),
    ("Ximena Ibarra", "Calidad de datos / QA", "Defiende conteos y controles."),
    ("Joel Ibarra", "Documentación y Trello", "Ubica entregables y seguimiento."),
]
for i, (name, role, task) in enumerate(roles):
    col, row = i % 2, i // 2
    x, y = 0.68 + col * 6.18, 1.92 + row * 1.35
    if i == 4:
        x, y = 3.77, 4.62
    add_rect(s, x, y, 5.86, 1.05, PAPER, line="E7DFD2")
    add_text(s, x + 0.2, y + 0.12, 5.45, 0.28, name, 13, GREEN, True)
    add_text(s, x + 0.2, y + 0.43, 2.75, 0.25, role, 10, BURGUNDY, True)
    add_text(s, x + 3.04, y + 0.43, 2.62, 0.39, task, 9, MUTED)
add_rect(s, 0.68, 6.18, 11.96, 0.53, PALE_GOLD)
add_text(s, 0.93, 6.29, 11.45, 0.28, "En la defensa, Joel lee los KPI y Ezequiel explica la decisión: ambos bloques quedan cubiertos.", 11, INK, True, valign=MSO_ANCHOR.MIDDLE)
footer(s, 2, total)
note(s, 0.75, "Presentamos responsabilidades para que sepan quién explica cada parte. La asignación de nombres y roles conserva el banco oficial. Como somos cinco, Joel apoya la lectura de los KPI en la exposición y Ezequiel interpreta la decisión comercial; el rol oficial de Ezequiel sigue siendo Líder + BI.", "Cada pregunta técnica la responde primero quien trabajó ese bloque.")

# 3 · Problema / objetivo y muestra disponible.
s = new_slide(prs)
heading(s, "01 · Contexto", "La pregunta: ¿qué compran nuestros clientes?", "Para contestarla, juntamos la venta con el perfil del cliente y la calidad del vino.")
cards = [
    ("fuente-punto-venta.png", "PUNTO DE VENTA", "5 ventas", "24 botellas · $22,760 MXN", (0.5, 0.5)),
    ("clientes-vinicola.png", "CRM", "4 clientes", "Membresía · ciudad · gasto", (0.72, 0.5)),
    ("uvas-dorado.png", "RATINGS", "3 vinos", "Puntaje · etiqueta · origen", (0.5, 0.5)),
]
for i, (img, label, metric, detail, focus) in enumerate(cards):
    x = 0.62 + i * 4.08
    add_rect(s, x, 2.02, 3.82, 3.45, PAPER, line="E7DFD2")
    add_photo(s, img, x + 0.1, 2.1, 3.62, 1.62, focus)
    add_text(s, x + 0.2, 3.91, 3.38, 0.24, label, 9, BURGUNDY, True)
    add_text(s, x + 0.2, 4.26, 3.4, 0.5, metric, 23, GREEN, True, face="Georgia")
    add_text(s, x + 0.2, 4.88, 3.38, 0.29, detail, 11, MUTED)
add_rect(s, 0.62, 5.79, 12.06, 0.79, PALE_GOLD)
add_text(s, 0.86, 5.93, 11.5, 0.58, "Base: 5 ventas. Para mostrar limpieza agregamos 2 filas POS y 1 rating sintéticos. No recibimos los archivos fuente ni datos de inventario o venta web.", 11, INK, True, valign=MSO_ANCHOR.MIDDLE)
footer(s, 3, total)
note(s, 1.0, "La pregunta analítica es sencilla: al conectar ventas, clientes y ratings podemos saber qué vino se vendió, por qué canal y a qué segmento. La base de demostración parte de cinco transacciones, cuatro clientes y tres vinos. Por indicación del profesor agregamos dos filas POS y un rating sintéticos para que se vea la limpieza. No recibimos los archivos originales ni datos de inventario o de venta web.", "Decimos claramente qué es muestra base y qué filas se añadieron solo para enseñar reglas.")

# 4 · Arquitectura Medallion con el asset requerido y corregido.
s = new_slide(prs)
heading(s, "02 · Arquitectura", "Bronce conserva · Plata limpia · Oro responde", "El flujo real implementado en SQL Server; el archivo fuente está en assets/.")
add_photo(s, "flujo_medallon_sql.png", 1.5, 1.72, 10.35, 5.18)
footer(s, 4, total)
note(s, 1.25, "Bronce guarda la entrada como texto y nos deja diagnosticarla. Plata aplica limpieza y conversiones, forma las dimensiones de clientes y vinos y prepara las ventas. Oro contiene el hecho de ventas y cinco vistas para operación, calidad y análisis. El diagrama aclara que usamos datos de muestra incluidos en SQL, no CSV o Excel que nunca recibimos.", "Oro es la capa de consumo; la tabla de ventas no se queda en Plata.")

# 5 · DER oficial, legible y con las llaves destacadas.
s = new_slide(prs)
heading(s, "03 · Modelo relacional", "Una venta se conecta con un cliente y un vino", "Las llaves primarias identifican; las foráneas protegen las relaciones en Oro.")
add_photo(s, "diagrama_der_sqlserver.png", 1.22, 1.9, 10.89, 5.1)
footer(s, 5, total)
note(s, 1.25, "El hecho Fact_Ventas_POS tiene como llave primaria el ID de venta. Sus llaves foráneas apuntan a las dimensiones de cliente y vino. Usamos VARCHAR para IDs, DATETIME2 para la fecha, DECIMAL para importes y puntajes e INT para botellas. La venta anónima se liga a CLI-MOSTRADOR para conservar el ingreso sin inventar una identidad.", "Las líneas entre el hecho Oro y las dimensiones Plata son FKs físicas; la zona de Bronce se transforma por ETL.")

# 6 · Evidencia real en SQL Server, no un mockup.
s = new_slide(prs, GREEN)
add_photo(s, "sqlserver_resultados.png", 6.7, 2.24, 6.0, 2.04)
add_text(s, 6.72, 4.58, 6.0, 0.35, "4 scripts SQL · 5 vistas · 7 procedimientos · reejecución sin cambio", 10, "D7B879", True)
add_rect(s, 0, 0, 6.55, H, GREEN, radius=False)
heading(s, "04 · Corrida real · 2–3 min", "SQL Server desde cero", "Patricio muestra la consola `sqlcmd` y el resultado.", dark=True)
steps = [
    ("01", "Bronce", "7 filas de entrada, incluidos ejemplos sucios."),
    ("02", "Plata", "Normaliza, elige la versión vigente y excluye errores."),
    ("03", "Oro", "5 ventas válidas; reejecutar no las duplica."),
]
for i, (num, title, desc) in enumerate(steps):
    y = 2.0 + i * 1.08
    add_rect(s, 0.68, y, 0.52, 0.52, GOLD)
    add_text(s, 0.68, y + 0.09, 0.52, 0.29, num, 13, GREEN, True, align=PP_ALIGN.CENTER)
    add_text(s, 1.43, y - 0.02, 5.8, 0.3, title, 15, WHITE, True)
    add_text(s, 1.45, y + 0.35, 5.8, 0.43, desc, 11, "E4DED2")
add_rect(s, 0.68, 5.44, 5.15, 0.98, "294D43")
add_text(s, 0.92, 5.61, 4.68, 0.61, "La captura y la salida son reales. Corrió en SQL Server 2022 temporal con Docker; no es SSMS.", 10, WHITE, True)
footer(s, 6, total)
note(s, 2.5, "La captura viene de una corrida real que ejecuté desde una base vacía en SQL Server 2022 Developer, usando sqlcmd dentro de un contenedor temporal. El script crea la base, ejecuta los cuatro SQL, consulta calidad, ventas, Rioja y reejecución. No es una interfaz SSMS ni una imagen simulada. Para mostrarlo en clase, abran los cuatro SQL en SSMS y sigan el mismo orden; esta captura es el respaldo verificado.", "Primero mostrar que corre; luego leer solo tres conteos y una venta.")


# 7 · Antes y después sencillo.
s = new_slide(prs, GREEN)
add_photo(s, "bodega-barricas.png", 7.5, 0, W - 7.5, H, focus=(0.67, 0.5))
add_rect(s, 0, 0, 7.55, H, GREEN, radius=False)
heading(s, "05 · Limpieza", "El dato cambia con una regla visible", "Un ejemplo por transformación. No hace falta leer todo el procedimiento.", dark=True)
examples = [
    ("' POS-805 '", "TRIM + ROW_NUMBER", "19:30", "Gana la versión más nueva"),
    ("cantidad: muchas", "TRY_CONVERT", "NULL", "POS-806 queda fuera de Oro"),
    ("rating: 120", "regla 0–100", "Excluido", "El registro sigue visible en Bronce"),
]
for i, (before, rule, after, why) in enumerate(examples):
    y = 2.0 + i * 1.14
    add_rect(s, 0.65, y, 6.15, 0.9, "294D43")
    add_text(s, 0.84, y + 0.15, 1.58, 0.26, before, 12, WHITE, True)
    add_text(s, 2.3, y + 0.16, 1.45, 0.25, rule, 10, "D7B879", True, align=PP_ALIGN.CENTER)
    add_text(s, 3.87, y + 0.12, 1.35, 0.3, after, 15, WHITE, True, face="Georgia", align=PP_ALIGN.CENTER)
    add_text(s, 5.14, y + 0.15, 1.45, 0.43, why, 9, "E2DDD4")
add_text(s, 0.84, 5.75, 5.95, 0.66, "También: ' Gold ' se normaliza y el gasto faltante se marca como proxy, no como dato confirmado.", 11, WHITE, True)
footer(s, 7, total)
note(s, 1.25, "Veamos la fila sucia. La segunda POS-805 trae espacios y una hora posterior. TRIM permite reconocer la misma llave y ROW_NUMBER deja una sola versión: la más reciente, a las 19:30. POS-806 trae la palabra muchas donde debería ir un entero; TRY_CONVERT devuelve NULL y la venta se excluye. Un rating de 120 también se excluye por estar fuera de 0 a 100. En Bronce los tres siguen visibles para explicar el porqué.", "Una regla por anomalía: limpiar, escoger o excluir; nunca esconder el valor original.")

# 8 · Reejecución y deduplicación demostradas.
s = new_slide(prs)
heading(s, "05 · Idempotencia", "Repetir el proceso no multiplica las ventas", "ROW_NUMBER elige una versión por ID; la llave de Oro protege la venta integrada.")
add_photo(s, "insight-de-negocio.png", 0.62, 1.85, 4.0, 4.74, focus=(0.7, 0.5))
add_rect(s, 4.95, 1.92, 7.7, 1.52, PAPER, line="E6DED2")
add_text(s, 5.25, 2.12, 7.1, 0.28, "PRUEBA DESDE CERO · SQL SERVER 2022", 10, BURGUNDY, True)
add_text(s, 5.25, 2.53, 7.0, 0.52, "7 filas Bronce  →  6 IDs  →  5 ventas Oro", 20, GREEN, True, face="Georgia")
add_rect(s, 4.95, 3.77, 7.7, 1.46, PALE_GREEN)
add_text(s, 5.25, 3.97, 7.05, 0.3, "PRUEBA DE DUPLICADO TARDÍO", 10, GREEN, True)
add_text(s, 5.25, 4.36, 7.05, 0.65, "El duplicado con espacios queda en Bronce; Plata elige 19:30. POS-806 se excluye porque 'muchas' no es un entero.", 13, INK, True)
add_rect(s, 4.95, 5.55, 7.7, 0.74, PALE_GOLD)
add_text(s, 5.2, 5.72, 7.18, 0.4, "Rerun: 5 ventas · 24 botellas · $22,760; el bloque de demo es sintético y está identificado.", 11, INK, True, valign=MSO_ANCHOR.MIDDLE)
footer(s, 8, total)
note(s, 1.0, "La muestra base tiene cinco ventas. La instrucción reciente pide enseñar datos sucios; por eso el archivo de ingesta agrega una corrección duplicada y dos valores inválidos sintéticos. El flujo reporta siete filas, seis IDs, un duplicado y una fila inválida; Oro publica cinco ventas. Reprocesar mantiene cinco ventas, 24 botellas y $22,760. Es una prueba reproducible, no una transacción real.", "Bronce guarda siete; Oro publica cinco válidas; rerun no las multiplica.")

# 9 · Calidad con números legibles.
s = new_slide(prs)
heading(s, "06 · Calidad y control", "La vista responde si el flujo fue limpio", "La salida de oro.vw_Calidad_Integracion, en cuatro lecturas.")
quality = [
    ("POS", "7 Bronce · 6 IDs · 1 duplicado · 1 inválida", "5 ventas Oro · 24 botellas · $22,760 MXN", BURGUNDY),
    ("Ratings", "4 en Bronce · 1 fuera de escala", "3 vinos válidos en Plata · rango permitido: 0–100", GREEN),
    ("CRM", "4 clientes · 1 gasto faltante", "$4,920 proxy marcado · no es gasto anual confirmado", GOLD),
    ("Relaciones", "0 clientes huérfanos · 0 vinos huérfanos", "1 venta anónima preservada como CLI-MOSTRADOR", GREEN2),
]
for i, (label, main, detail, tone) in enumerate(quality):
    y = 2.0 + i * 1.02
    add_rect(s, 0.75, y, 11.85, 0.82, PAPER, line="E7DFD2")
    add_rect(s, 0.75, y, 1.55, 0.82, tone, radius=False)
    add_text(s, 0.88, y + 0.22, 1.29, 0.32, label, 12, WHITE, True, align=PP_ALIGN.CENTER)
    add_text(s, 2.55, y + 0.13, 9.7, 0.27, main, 13, INK, True)
    add_text(s, 2.55, y + 0.48, 9.7, 0.22, detail, 10, MUTED)
add_text(s, 0.8, 6.36, 11.8, 0.35, "Conteos comprobados en SQL Server; aplican a la muestra, no a fuentes completas del negocio.", 11, INK, True)
footer(s, 9, total)
note(s, 1.5, "Ximena lee cuatro resultados de la vista de calidad. En POS hubo siete filas de entrada, un ID repetido, una cantidad inválida y cinco ventas válidas; no faltan clientes ni vinos y una venta anónima se conserva. Ratings tiene una fila fuera de rango. CRM tiene un proxy explícitamente marcado. Estos resultados describen solo esta muestra.", "La vista hace visible lo que entró, lo que se corrigió y lo que llegó a Oro.")

# 10 · Insight de negocio, limitación estadística visible.
s = new_slide(prs)
add_photo(s, "insight-de-negocio.png", 0, 0, 5.25, H, focus=(0.68, 0.5))
add_rect(s, 5.25, 0, W - 5.25, H, IVORY, radius=False)
add_text(s, 5.83, 0.48, 6.8, 0.25, "07 · ORO · LECTURA DE NEGOCIO", 10, BURGUNDY, True)
add_text(s, 5.8, 0.88, 6.8, 0.62, "Una señal para probar", 28, INK, True, face="Georgia")
add_text(s, 5.83, 1.58, 6.7, 0.33, "Vista oro.vw_Gold_Ventas_Vinos + KPIs por origen y membresía.", 12, MUTED)
kpis = [("$22,760", "ventas de muestra"), ("63.27%", "ingreso asociado a Rioja"), ("12 / 15", "botellas Platinum >93")]
for i, (value, label) in enumerate(kpis):
    y = 2.17 + i * 0.91
    add_text(s, 5.85, y, 2.5, 0.52, value, 24, GREEN if i != 1 else BURGUNDY, True, face="Georgia")
    add_text(s, 8.55, y + 0.09, 3.8, 0.36, label, 12, INK, True)
add_rect(s, 5.8, 5.05, 6.9, 1.15, PALE_GOLD)
add_text(s, 6.04, 5.2, 6.45, 0.83, "Rioja suma $14,400. Las 12 botellas con puntaje >93 también suman $14,400, pero las compró una sola persona. Correlación de esta muestra; no demuestra causalidad.", 11, INK, True, valign=MSO_ANCHOR.MIDDLE)
add_text(s, 5.85, 6.51, 6.5, 0.25, "Idea: probar recomendación y medir conversión con más clientes.", 11, GREEN, True)
footer(s, 10, total)
note(s, 2.0, "Las cinco ventas suman veintidós mil setecientos sesenta pesos. Rioja aporta catorce mil cuatrocientos pesos, que son 63.27 por ciento de los ingresos. Los vinos con más de 93 puntos también suman catorce mil cuatrocientos, pero las doce botellas corresponden a una sola persona. No concluimos que el puntaje causó la compra. La decisión prudente es probar una recomendación con más clientes y medir conversión e ingreso incremental.", "Una hipótesis medible; no una conclusión causal.")

# 11 · Límites y trabajo no implementado.
s = new_slide(prs)
heading(s, "CIERRE · Límites claros", "Lo que este proyecto todavía no puede afirmar", "Separar lo implementado de lo que dependería de otras fuentes.")
add_photo(s, "clientes-vinicola.png", 0.62, 1.88, 4.35, 4.72, focus=(0.72, 0.5))
limits = [
    ("Sin archivos originales", "La demo usa la muestra cargada desde SQL; no prueba ingesta desde CSV/Excel reales."),
    ("Sin inventario ni e-commerce", "No hay base para recomendar reabasto ni medir conversión en línea."),
    ("Muestra de 5 ventas", "Los patrones son señales para validar, no una predicción estable."),
    ("Customer 360 separado", "Tickets, Interacciones y Ventas no están en este modelo vinícola."),
]
for i, (head, desc) in enumerate(limits):
    y = 1.92 + i * 1.11
    add_rect(s, 5.3, y, 7.25, 0.9, PAPER, line="E6DED2")
    add_text(s, 5.55, y + 0.12, 2.5, 0.28, head, 11, BURGUNDY, True)
    add_text(s, 8.05, y + 0.12, 4.2, 0.56, desc, 10, INK)
footer(s, 11, total)
note(s, 0.5, "Hay cuatro límites: faltan fuentes originales, no hay inventario ni e-commerce, la muestra es pequeña y Customer 360 es un entregable separado que no está modelado aquí. Para el diccionario separado necesitamos sus definiciones fuente.", "Ser claros sobre el alcance nos permite defender mejor lo implementado.")

# 12 · Entregables / dónde están / pendientes reales.
s = new_slide(prs, GREEN)
add_photo(s, "portada-vinicola-golden-hour.png", 7.35, 0, W - 7.35, H, focus=(0.68, 0.52))
add_rect(s, 0, 0, 7.42, H, GREEN, radius=False)
heading(s, "08 · Entrega", "Código, visuales y defensa en un solo lugar", "Abrir el clon en GitHub Desktop y después mostrar el tablero privado de Trello.", dark=True)
deliveries = [
    ("src/", "4 scripts SQL · orden 01 → 04"),
    ("assets/", "logo, flujo Medallón, DER y fotos"),
    ("docs/", "PPT/PDF, guion, Q&A, log y captura SQL real"),
    ("tasks/", "corrida limpia y reproducible con Docker"),
]
for i, (name, desc) in enumerate(deliveries):
    y = 2.0 + i * 0.71
    add_text(s, 0.75, y, 1.65, 0.3, name, 13, "D7B879", True)
    add_text(s, 2.35, y, 4.35, 0.37, desc, 12, WHITE)
add_rect(s, 0.72, 5.15, 6.18, 1.25, "294D43")
add_text(s, 0.95, 5.34, 5.72, 0.85, "GitHub Desktop: mostrar el clon y la rama local; abrir src/, assets/ y README. Moodle: abre 24-nov 11:00; cierra 26-nov 15:00.", 11, WHITE, True, valign=MSO_ANCHOR.MIDDLE)
footer(s, 12, total)
note(s, 1.0, "Mostramos el repositorio: los cuatro SQL, la carpeta de imágenes, los documentos y la captura de la corrida de verdad. El README explica el alcance y el comando que crea un SQL Server desechable desde cero. El tablero de Trello y la entrega en Moodle siguen siendo superficies externas que se verifican por separado.", "El repositorio contiene fuente reproducible y evidencia real.")

# 13 · cierre que se puede decir sin leer.
s = new_slide(prs, GREEN)
add_photo(s, "uvas-dorado.png", 0, 0, 5.0, H, focus=(0.52, 0.5))
add_rect(s, 5.0, 0, W - 5.0, H, GREEN, radius=False)
add_text(s, 5.75, 0.78, 6.6, 0.26, "CIERRE · EQUIPO 2", 10, "D7B879", True)
add_text(s, 5.75, 1.35, 6.65, 1.2, "Integramos para\npreguntar mejor.", 30, WHITE, True, face="Georgia")
add_text(s, 5.8, 3.0, 6.4, 0.9, "El siguiente paso es probar la hipótesis con más ventas, perfiles y medición de conversión.", 16, "E8E1D6")
add_rect(s, 5.8, 4.45, 3.4, 0.47, "2B5548")
add_text(s, 5.91, 4.55, 3.16, 0.25, "¿PREGUNTAS? · 8 MIN", 11, WHITE, True, align=PP_ALIGN.CENTER)
add_text(s, 5.8, 5.4, 6.25, 0.6, "Gracias. Ahora respondemos dos preguntas por integrante con evidencia del SQL y las vistas.", 13, WHITE, True)
add_text(s, 0.62, 7.16, 4.0, 0.18, "INTEGRACIÓN DE DATOS · EQUIPO 2", 8, WHITE, True)
add_text(s, 11.9, 7.13, 0.78, 0.22, "13 / 13", 9, WHITE, True, align=PP_ALIGN.RIGHT)
note(s, 0.5, "Integramos estos datos para hacer una mejor pregunta de negocio. El siguiente paso es ampliar la muestra y medir si una recomendación realmente cambia la conversión. Gracias. Estamos listos para las preguntas.", "Cierre con la limitación y el siguiente paso medible.")

prs.save(OUT)
print(OUT)
