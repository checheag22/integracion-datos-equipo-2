from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN

PPTX = 'docs/presentacion-final-equipo-2.pptx'
PHOTO = 'assets/portada-vinicola-golden-hour.png'
prs = Presentation(PPTX)
slide = prs.slides[0]
# Remove all cover shapes and rebuild a clean, fully editable title/role layout.
sp = slide.shapes._spTree
for el in list(sp):
    if el.tag.endswith('}sp') or el.tag.endswith('}pic') or el.tag.endswith('}graphicFrame') or el.tag.endswith('}grpSp'):
        sp.remove(el)
slide.shapes.add_picture(PHOTO, 0, 0, width=Inches(7.15), height=prs.slide_height)
panel = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(7.15), 0, prs.slide_width-Inches(7.15), prs.slide_height)
panel.fill.solid(); panel.fill.fore_color.rgb=RGBColor(48,22,30); panel.line.fill.background()

def txt(x,y,w,h,text,size,color,bold=False,font='Aptos',align=None):
    sh=slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf=sh.text_frame; tf.clear(); tf.word_wrap=True
    tf.margin_left=0; tf.margin_right=0; tf.margin_top=0; tf.margin_bottom=0
    p=tf.paragraphs[0]; p.text=text
    if align is not None: p.alignment=align
    for r in p.runs:
        r.font.name=font; r.font.size=Pt(size); r.font.bold=bold; r.font.color.rgb=color
    return sh
cream=RGBColor(250,245,236); gold=RGBColor(210,170,94); muted=RGBColor(218,198,175)
txt(7.72,.64,5.05,.26,'PROYECTO FINAL  ·  INTEGRACIÓN DE DATOS',11,gold,True)
txt(7.72,1.05,5.05,1.22,'Una vinícola,\nuna vista integrada',31,cream,True)
txt(7.72,2.48,4.9,.7,'POS + CRM + calificaciones de vino\nMicrosoft SQL Server  ·  Equipo 2',14,muted)
txt(7.72,3.35,4.95,.65,'Demo 2–3 min  ·  Exposición 12–15 min\nDefensa individual por rol 6–8 min',11,muted)
txt(7.72,4.18,4.9,.26,'EQUIPO Y RESPONSABILIDADES',11,gold,True)
roles=[('Ezequiel Aguilera','Líder de Proyecto'),('José Hernández','Data Architect / SQL Specialist'),('Patricio García','Data Engineer / Pipeline Lead'),('Ximena Ibarra','Data Quality & QA Specialist'),('Joel Ibarra','BI & Analytics Specialist')]
for i,(name,role) in enumerate(roles):
    y=4.57+i*.43
    txt(7.72,y,2.12,.25,name,11,cream,True)
    txt(9.86,y,3.07,.29,role,10,muted)
txt(.38,7.08,6.3,.2,'Muestra: 5 transacciones POS · 4 clientes · 3 vinos',9,cream,False)
txt(12.35,7.13,.5,.2,'01/08',8,gold,True)

# Add a truthful, concrete before/after sample to the ETL slide.
etl=prs.slides[4]
box=etl.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, Inches(.75), Inches(5.42), Inches(11.8), Inches(.55))
box.fill.solid(); box.fill.fore_color.rgb=RGBColor(247,239,226); box.line.color.rgb=RGBColor(219,203,181)
tf=box.text_frame; tf.clear(); tf.margin_left=Inches(.16); tf.margin_right=Inches(.12); tf.margin_top=Inches(.09)
p=tf.paragraphs[0]
p.text="EJEMPLO DE LA MUESTRA · Bronce: Nombre=' sofia mendiolea ' | Categoría=' Gold ' | Gasto=NULL   →   Plata: TRIM conserva 'sofia mendiolea'; UPPER deja 'GOLD'; gasto faltante = $4,920 como proxy imputado."
for r in p.runs: r.font.name='Aptos'; r.font.size=Pt(12); r.font.color.rgb=RGBColor(58,44,38)
prs.save(PPTX)
