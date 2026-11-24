from pathlib import Path
import re
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt
from PIL import Image

BASE=Path(__file__).resolve().parents[1]; A=BASE/'assets/vinicola'; OUT=BASE/'docs/presentacion-final-equipo-2.pptx'
BLUE='1746B3'; ORANGE='F05A24'; INK='17212B'; GRAY='5E6975'; PALE='F3F6FA'; WHITE='FFFFFF'
P=Presentation(); P.slide_width=Inches(13.333); P.slide_height=Inches(7.5)
def rgb(c): return RGBColor.from_string(c)
def rect(s,x,y,w,h,c,r=False,line=None):
 sh=s.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE if r else MSO_SHAPE.RECTANGLE,Inches(x),Inches(y),Inches(w),Inches(h)); sh.fill.solid(); sh.fill.fore_color.rgb=rgb(c)
 if line: sh.line.color.rgb=rgb(line); sh.line.width=Pt(1)
 else: sh.line.fill.background()
 if r:
  try: sh.adjustments[0]=.08
  except: pass
 return sh
def text(s,x,y,w,h,t,size=14,c=INK,b=False,align=PP_ALIGN.LEFT,va=MSO_ANCHOR.TOP,face='Arial',m=.03):
 sh=s.shapes.add_textbox(Inches(x),Inches(y),Inches(w),Inches(h)); tf=sh.text_frame; tf.clear(); tf.word_wrap=True; tf.margin_left=tf.margin_right=Inches(m); tf.margin_top=tf.margin_bottom=Inches(m); tf.vertical_anchor=va
 p=tf.paragraphs[0]; p.alignment=align; r=p.add_run(); r.text=t; r.font.name=face; r.font.size=Pt(size); r.font.bold=b; r.font.color.rgb=rgb(c); return sh
def img(s,f,x,y,w,h,cover=False,focus=.28):
 path=A/f
 with Image.open(path) as im: sw,sh=im.size
 if cover:
  pic=s.shapes.add_picture(str(path),Inches(x),Inches(y),width=Inches(w),height=Inches(h))
  src,target=sw/sh,w/h
  if src>target:
   crop=1-target/src; pic.crop_left=crop*focus; pic.crop_right=crop*(1-focus)
  elif src<target:
   crop=1-src/target; pic.crop_top=pic.crop_bottom=crop/2
  return pic
 scale=min(w/sw,h/sh); fw,fh=sw*scale,sh*scale
 return s.shapes.add_picture(str(path),Inches(x+(w-fw)/2),Inches(y+(h-fh)/2),width=Inches(fw),height=Inches(fh))
def slide(bg=WHITE):
 s=P.slides.add_slide(P.slide_layouts[6]); s.background.fill.solid(); s.background.fill.fore_color.rgb=rgb(bg); return s
def head(s,tag,title,sub='',dark=False):
 text(s,.62,.27,12,.23,tag.upper(),10,'CFE0FF' if dark else BLUE,True); text(s,.62,.61,12.1,.65,title,27,WHITE if dark else INK,True,face='Arial')
 if sub:text(s,.64,1.31,12,.36,sub,13,'DCE8FF' if dark else GRAY)
def foot(s,n,dark=False):
 text(s,.62,7.12,8,.18,'INTEGRACIÓN DE DATOS · EQUIPO 2',8,'FFFFFF' if dark else GRAY,True); text(s,11.92,7.1,.78,.19,f'{n:02d} / 14',9,'FFFFFF' if dark else GRAY,True,align=PP_ALIGN.RIGHT)
def note(s,mins,who,body,remember): s.notes_slide.notes_text_frame.text=f'TIEMPO: {mins} min\n\nQUIÉN EXPONE\n{who}\n\nQUÉ DECIR\n{body}\n\nIDEA PARA RECORDAR\n{remember}'
def card(s,x,y,w,h,label,body,accent=BLUE):
 rect(s,x,y,w,h,PALE,True,'DCE4EE'); rect(s,x,y,.12,h,accent); text(s,x+.25,y+.13,w-.48,.24,label.upper(),10,accent,True); text(s,x+.25,y+.43,w-.5,h-.49,body,14,INK,True)

# 1 cover
s=slide(BLUE); img(s,'portada.png',0,0,6.15,7.5,cover=True); rect(s,6.15,0,7.18,7.5,BLUE); text(s,6.72,.78,5.8,.25,'PROYECTO INTEGRADOR · SQL SERVER',11,'CFE0FF',True); text(s,6.68,1.32,5.9,1.5,'Del ticket a una\nrespuesta confiable',32,WHITE,True,face='Arial'); text(s,6.73,3.23,5.6,.85,'¿Qué vendimos, a quién y qué podemos concluir?',19,WHITE); rect(s,6.75,4.42,4.45,.55,ORANGE,True); text(s,6.9,4.55,4.15,.22,'CASO FICTICIO · VIÑEDOS DEL ALBA',10,WHITE,True,align=PP_ALIGN.CENTER); text(s,6.74,5.35,5.7,.6,'Ezequiel · José · Patricio · Ximena · Joel\nEquipo 2 · Universidad Iberoamericana León',12,WHITE,True); foot(s,1,True); note(s,1,'Ezequiel','Somos el Equipo 2. Vamos a seguir una venta desde el ticket hasta una respuesta que podamos explicar. Veremos qué significa integrar datos con un ejemplo sencillo, cómo lo resolvimos en SQL Server y qué conclusiones permite la muestra. Viñedos del Alba es ficticio.','Una venta, tres fuentes, una respuesta comprobable.')
# 2 question
s=slide(); head(s,'Punto de partida','Una venta sola no cuenta toda la historia','El ticket dice qué se vendió; para conocer a la persona y al vino, necesitamos otras fuentes.'); img(s,'fuentes.png',.58,1.82,7.35,4.55); card(s,8.22,1.95,4.25,1.12,'La pregunta','¿Qué compran nuestros clientes?'); card(s,8.22,3.38,4.25,1.12,'Para responder','Conectar venta + cliente + vino.',ORANGE); card(s,8.22,4.81,4.25,1.12,'Lo que buscamos','Una respuesta útil y rastreable.'); foot(s,2); note(s,1.75,'Ezequiel','Pensemos en un ticket de compra. Por sí solo dice producto, cantidad, precio y hora. Si queremos saber qué tipo de cliente compró o qué características tiene el vino, buscamos esa información en otros registros. La pregunta guía el trabajo: no unimos tablas por unirlas, las conectamos para responder algo concreto.','La pregunta aparece antes que la tecnología.')
# 3 theory
s=slide(PALE); head(s,'La idea en sencillo','Integrar datos es unir pistas que hablan de lo mismo','Una referencia compartida permite reconocer que dos registros describen la misma cosa.'); rect(s,.74,1.9,5.25,3.95,WHITE,True,'DCE4EE'); text(s,1.02,2.23,4.7,.4,'Como armar una compra completa',20,BLUE,True)
for i,(a,b) in enumerate([('Ticket','lo que se compró'),('Ficha de cliente','quién compró'),('Ficha del vino','qué vino fue')]):
 y=2.96+i*.78; rect(s,1.03,y,2.15,.54,BLUE if i==0 else ORANGE,True); text(s,1.1,y+.12,2.02,.26,a,11,WHITE,True,align=PP_ALIGN.CENTER); text(s,3.42,y+.11,2.28,.36,b,12,INK,True)
img(s,'relaciones.png',6.38,1.92,6.3,3.95); rect(s,.74,6.08,11.91,.56,BLUE,True); text(s,.95,6.22,11.5,.22,'ID_Cliente identifica a la persona · SKU_Vino identifica el producto',13,WHITE,True,align=PP_ALIGN.CENTER); foot(s,3); note(s,1.75,'José','Integrar datos significa relacionar información de fuentes distintas que se refiere a la misma venta, cliente o vino. Una analogía: ticket, ficha del cliente y ficha de producto forman una historia completa si comparten una referencia. En la base, ID_Cliente y SKU_Vino cumplen ese papel. Así no dependemos de nombres que podrían escribirse de distintas formas.','Una llave compartida hace que las piezas encajen.')
#4 sources
s=slide(); head(s,'De dónde viene la información','Cada fuente aporta una parte distinta','El diagrama fue generado como imagen; las etiquetas resumen el modelo del proyecto.'); img(s,'fuentes.png',.68,1.64,11.98,4.82); text(s,.85,6.58,11.6,.22,'POS = ventas   ·   CRM = clientes   ·   Ratings = puntajes del vino',12,GRAY,True,align=PP_ALIGN.CENTER); foot(s,4); note(s,1.75,'José','POS registra qué se vendió y cuándo. CRM describe al cliente: membresía o ciudad. Ratings contiene la evaluación del vino. Para integrar, POS aporta ID_Cliente y SKU_Vino. No recibimos archivos originales; usamos registros de demostración cargados en SQL Server.','POS cuenta la venta, CRM al cliente y Ratings al vino.')
#5 model
s=slide(PALE); head(s,'Cómo se conectan','La venta queda en medio de dos relaciones','Las llaves guardan el vínculo entre cada transacción y sus dimensiones.'); img(s,'relaciones.png',.58,1.7,12.15,4.65); card(s,1.0,6.15,5.35,.76,'Cliente → venta','ID_Cliente'); card(s,6.95,6.15,5.35,.76,'Venta → vino','SKU_Vino',ORANGE); foot(s,5); note(s,1.5,'José','El modelo se entiende como cliente, venta, vino. La venta tiene su identificador y referencia al cliente y al vino con llaves foráneas. SQL Server ayuda a evitar vínculos a clientes o productos inexistentes. Para ventas sin identidad individual usamos CLI-MOSTRADOR, que conserva el ingreso sin inventar quién compró.','Las llaves explican la unión y cuidan la consistencia.')
#6 layers
s=slide(); head(s,'El recorrido del dato','Tres etapas: guardar, ordenar y responder','Así separamos lo recibido, lo limpio y lo listo para consultar.'); img(s,'capas.png',.62,1.58,12.05,4.88); text(s,.85,6.5,11.6,.24,'Bronce conserva la entrada · Plata limpia y relaciona · Oro presenta resultados',12,INK,True,align=PP_ALIGN.CENTER); foot(s,6); note(s,2,'Patricio','Bronce guarda la entrada, incluso si está sucia. Plata aplica reglas para quitar espacios, convertir tipos, validar puntajes y resolver duplicados; también crea las dimensiones de clientes y vinos. Oro publica ventas integradas y vistas para consulta. Las capas permiten revisar qué llegó, qué corregimos y qué resultado usamos.','Bronce guarda, Plata ordena y Oro responde.')
#7 example
s=slide(PALE); head(s,'Un ejemplo concreto','POS-805 llegó dos veces; dejamos una versión','La regla compara las horas y conserva la más reciente.'); img(s,'duplicado.png',.55,1.7,12.25,4.6); rect(s,1.32,6.35,10.7,.53,BLUE,True); text(s,1.52,6.48,10.3,.22,'19:15 = versión anterior   →   19:30 = versión que pasa a Oro',13,WHITE,True,align=PP_ALIGN.CENTER); foot(s,7); note(s,1.75,'Patricio','POS-805 aparece dos veces: a las 19:15 y a las 19:30, con espacios en el identificador. Plata quita el espacio y compara por hora. Conserva la más reciente. Bronce mantiene las dos entradas, por lo que se puede explicar la regla. En Oro queda una venta.','Se guarda evidencia y se elige una sola versión vigente.')
#8 SQL evidence
s=slide(BLUE); head(s,'Demostración en SQL Server','Lo ejecutamos desde una base vacía','Crear estructura → cargar Bronce → transformar Plata → publicar Oro.',True); img(s,'evidencia-sql.png',.72,1.75,11.9,3.08)
for i,(v,l) in enumerate([('7 → 6 → 5','filas hasta Oro'),('24','botellas válidas'),('$22,760','ingreso de muestra')]):
 x=.9+i*4.05; rect(s,x,5.12,3.65,1,WHITE,True); text(s,x+.18,5.25,3.28,.38,v,21,BLUE,True,align=PP_ALIGN.CENTER); text(s,x+.18,5.69,3.28,.2,l,10,GRAY,True,align=PP_ALIGN.CENTER)
text(s,.82,6.42,11.7,.22,'Captura real de sqlcmd y SQL Server 2022; no es una interfaz simulada.',10,'DCE8FF',True,align=PP_ALIGN.CENTER); foot(s,8,True); note(s,4,'Patricio','Esta es la evidencia de la corrida real en SQL Server 2022. Se ejecutó desde una base vacía siguiendo los scripts: crear tablas y llaves; cargar Bronce; limpiar y relacionar en Plata; publicar Oro; y consultar resultados. La captura viene de sqlcmd conectado a un contenedor temporal. Los números resumen la ejecución: siete filas POS en Bronce, seis IDs después de normalizar y cinco ventas en Oro. Quedan 24 botellas y 22,760 pesos. También se verificaron cinco vistas y siete procedimientos.','La captura demuestra una corrida reproducible desde cero.')
#9 quality
s=slide(); head(s,'Qué cambió al limpiar','De siete filas recibidas quedaron cinco ventas válidas','Cada diferencia tiene una regla que podemos revisar.');
for i,(num,label,detail,ac) in enumerate([('7','filas POS','lo que llegó',BLUE),('6','IDs únicos','una venta repetida',ORANGE),('5','ventas Oro','una cantidad inválida no pasa',BLUE)]):
 x=.7+i*4.25; rect(s,x,2.05,3.85,2.18,PALE,True,'DCE4EE'); text(s,x+.2,2.31,3.45,.72,num,40,ac,True,align=PP_ALIGN.CENTER,face='Arial'); text(s,x+.2,3.08,3.45,.31,label,17,INK,True,align=PP_ALIGN.CENTER); text(s,x+.18,3.58,3.49,.35,detail,11,GRAY,align=PP_ALIGN.CENTER)
img(s,'duplicado.png',.86,4.55,6.05,1.73); card(s,7.2,4.76,4.9,1.12,'Otro control','Un rating de 120 no cumple el rango 0–100.',ORANGE); foot(s,9); note(s,1.75,'Ximena','Entraron siete filas POS. Al limpiar las llaves, vemos seis identificadores: había una venta con dos versiones. Otra fila tiene “muchas” en lugar de cantidad numérica; no pasa a Oro y quedan cinco ventas. Ratings tiene cuatro filas, pero el valor 120 no cumple el rango 0 a 100; tres son válidas. Los registros de prueba son sintéticos.','Los conteos explican por qué cambia el resultado.')
#10 views
s=slide(PALE); head(s,'Qué podemos consultar','Cada vista responde una pregunta de trabajo','Cinco consultas preparadas para reutilizar.'); views=[('Detalle de ventas','¿Qué pasó en cada transacción?'),('Ventas integradas','¿Qué se vendió y a qué cliente?'),('Membresía y canal','¿Cómo se distribuye el ingreso?'),('Origen del vino','¿Qué origen aporta más ventas?'),('Calidad de integración','¿Qué filas pasaron y cuáles requieren atención?')]
for i,(a,b) in enumerate(views):
 y=1.8+i*.87; rect(s,.88,y,11.55,.68,WHITE,True,'DCE4EE'); rect(s,1.06,y+.11,.46,.46,BLUE if i%2==0 else ORANGE,True); text(s,1.76,y+.16,3.1,.25,a,13,INK,True); text(s,4.98,y+.16,7,.25,b,13,GRAY)
foot(s,10); note(s,1.5,'Joel','Las vistas guardan consultas listas. La de detalle permite revisar una transacción; la integrada combina venta, cliente y vino. Otras resumen por membresía y canal o por origen del vino. La vista de calidad muestra cómo quedó la carga. Las cinco se consultaron. No memoricen los nombres técnicos: recuerden la pregunta que resuelve cada una.','Una vista preparada responde una pregunta frecuente.')
#11 insight
s=slide(); head(s,'Qué nos dice la muestra','Rioja concentra una parte importante del ingreso','Es una señal para investigar; no demuestra qué causó la compra.'); rect(s,.72,1.82,4.15,4.52,BLUE,True); text(s,1.0,2.25,3.55,.3,'INGRESO OBSERVADO',11,'CFE0FF',True,align=PP_ALIGN.CENTER); text(s,.98,2.87,3.58,.76,'$22,760',36,WHITE,True,align=PP_ALIGN.CENTER); text(s,1.05,3.82,3.45,.65,'Rioja: $14,400\n63.27% del ingreso',17,WHITE,True,align=PP_ALIGN.CENTER); card(s,5.42,1.95,6.65,1.14,'Otra señal','12 botellas con puntaje >93 en una compra.',ORANGE); card(s,5.42,3.42,6.65,1.14,'Lo que sí podemos decir','Eso ocurrió en esta muestra de cinco ventas.'); card(s,5.42,4.89,6.65,1.14,'Lo que no podemos afirmar','El puntaje causó la compra o representa a todos.',ORANGE); foot(s,11); note(s,1.75,'Ezequiel','En esta muestra, Rioja representa 14,400 pesos, o 63.27% del total. También vemos doce botellas con puntaje superior a 93 en una compra de una persona. Son observaciones, no una regla general. No tenemos suficiente historial para afirmar que el puntaje alto causó más ventas ni que esto se repita.','Describir con precisión y no prometer más de lo que muestran los datos.')
#12 limits
s=slide(PALE); head(s,'Alcance real','Qué falta para usar esto con datos del negocio','El proyecto demuestra el flujo SQL; todavía no reemplaza un sistema productivo.');
for i,(a,b) in enumerate([('Archivos reales','No recibimos los CSV/Excel originales.'),('Más historial','Cinco ventas demuestran reglas, no generalizan.'),('Inventario y web','No hay datos para medir stock o conversión.'),('Gastos proxy','Un gasto estimado está señalado como aproximación.')]):
 x=.78+(i%2)*6.15; y=1.93+(i//2)*2.05; card(s,x,y,5.65,1.42,a,b,BLUE if i%2==0 else ORANGE)
foot(s,12); note(s,1.5,'Ximena','Hay límites. No conectamos archivos originales. La muestra es pequeña. No tenemos datos de inventario ni e-commerce. Además, un gasto se marcó como proxy. Para usarlo como análisis del negocio hacen falta datos originales y más periodos.','La demostración está probada; el análisis real depende de las fuentes.')
#13 next steps
s=slide(); head(s,'Siguiente paso','Primero mejorar la entrada; después ampliar el análisis','Las mejoras responden a brechas concretas.');
for i,(n,a,b) in enumerate([('1','Cargar archivos originales','Registrar origen y fecha de cada carga.'),('2','Guardar rechazos','Anotar fila y razón de cada dato inválido.'),('3','Ampliar periodo','Comprobar si los patrones se mantienen.'),('4','Añadir inventario','Solo cuando exista una fuente confiable.')]):
 y=1.77+i*1.07; rect(s,.9,y,11.5,.82,PALE,True,'DCE4EE'); rect(s,1.08,y+.15,.5,.5,ORANGE if i%2 else BLUE,True); text(s,1.17,y+.25,.3,.2,n,12,WHITE,True,align=PP_ALIGN.CENTER); text(s,1.85,y+.13,3.25,.26,a,13,INK,True); text(s,5.25,y+.16,6.7,.25,b,12,GRAY)
rect(s,1,6.24,11.2,.47,BLUE,True); text(s,1.2,6.37,10.8,.2,'Trello organiza el seguimiento · GitHub conserva los archivos · Moodle recibe la entrega',11,WHITE,True,align=PP_ALIGN.CENTER); foot(s,13); note(s,1.5,'Joel','Las mejoras siguen lo que falta. Con archivos originales documentamos cada carga; guardamos también las filas rechazadas y su razón. Con más historial comprobamos los patrones. Inventario se añade cuando exista una fuente confiable. Trello organiza las tareas, GitHub conserva el proyecto y Moodle es donde se entrega.','Mejorar sobre lo disponible y distinguir lo implementado de lo futuro.')
#14 closing
s=slide(BLUE); img(s,'portada.png',0,0,5,7.5,cover=True); rect(s,5,0,8.33,7.5,BLUE); text(s,5.72,.85,6.5,.3,'EN UNA FRASE',11,'CFE0FF',True); text(s,5.68,1.42,6.7,1.18,'Conectamos datos\npara responder mejor.',31,WHITE,True,face='Arial'); text(s,5.75,3.13,6.1,.85,'Guardamos lo recibido, limpiamos diferencias y consultamos una muestra reproducible.',17,WHITE); rect(s,5.76,4.55,3.65,.62,ORANGE,True); text(s,5.91,4.73,3.35,.23,'25 MINUTOS · PREGUNTAS AL FINAL',10,WHITE,True,align=PP_ALIGN.CENTER); text(s,5.76,5.55,6.5,.48,'Gracias. ¿Qué parte del recorrido quieren que expliquemos?',14,WHITE,True); foot(s,14,True); note(s,1.5,'Ezequiel','La idea principal es que conectar registros con llaves y reglas visibles nos permite responder preguntas sin ocultar errores. La corrida funciona desde cero para esta muestra. Gracias. Ahora abrimos las preguntas.','Conectar, limpiar y explicar.')
guide=(BASE/'docs/vinicola/Guion_Exposicion_25_Minutos.md').read_text()
parts=list(re.finditer(r'(?m)^## (\d+)\. (.*?) · ([0-9:]+) · (.+)$',guide))
for idx,match in enumerate(parts):
 start=match.end(); end=parts[idx+1].start() if idx+1<len(parts) else guide.find('\n## Recordatorio para los cinco',start)
 body=guide[start:end].strip()
 body=re.sub(r'(?m)^\*\*Transición:\*\*.*$', '', body).strip()
 body=re.sub(r'(?m)^\*\*(.*?)\*\*\s*$', r'\1', body)
 body=re.sub(r'(?m)^>\s?', '', body)
 mm,ss=(int(x) for x in match.group(3).split(':')); minutes=mm+ss/60
 s=P.slides[int(match.group(1))-1]
 s.notes_slide.notes_text_frame.text=f'TIEMPO: {minutes:g} min\n\nQUIÉN EXPONE\n{match.group(4).strip()}\n\nQUÉ DECIR\n{body}'
P.save(OUT); print(OUT)
