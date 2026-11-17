-- Datos de inicio reproducibles: curso original de Academix Móvil.
-- Videos MP4 incluidos en assets/videos de la aplicación.
-- Requiere antes la migración 20261030_mobile_learning.sql.
-- NO se generan certificados ni inscripciones ficticias.

insert into public.mobile_courses(id,slug,title,description,category,instructor,price,status) values ('ce552b9b-abec-5881-97fc-4d3fc5cfa2e8','web-fundamentos-academix','Fundamentos de Desarrollo Web: HTML, CSS y JavaScript','Aprende a construir tus primeras páginas web mediante tres videolecciones y evaluaciones prácticas.', 'Desarrollo Web','Equipo Academix',0,'published') on conflict (id) do update set title=excluded.title, description=excluded.description, status=excluded.status, price=excluded.price;

insert into public.mobile_modules(id,course_id,title,position) values ('ad9abdd1-350e-509d-928d-dbb8f9abaf27','ce552b9b-abec-5881-97fc-4d3fc5cfa2e8','Introducción al desarrollo web',1) on conflict (id) do update set title=excluded.title;

insert into public.mobile_lessons(id,module_id,title,description,position,video_asset,duration_minutes,is_preview) values ('6fe2ba86-82e8-577f-9340-283455b3f2b5','ad9abdd1-350e-509d-928d-dbb8f9abaf27','HTML: estructura de una página','Aprende qué es HTML, cómo organizar encabezados y párrafos, y por qué es importante la semántica.',1,'assets/videos/01_html.mp4',1,false) on conflict (id) do update set title=excluded.title, description=excluded.description,video_asset=excluded.video_asset;

insert into public.mobile_quiz_questions(id,lesson_id,prompt,position) values ('b773f033-c4f0-5f75-982b-261cec99d02c','6fe2ba86-82e8-577f-9340-283455b3f2b5','¿Cuál etiqueta representa el encabezado principal?',1) on conflict(id) do update set prompt=excluded.prompt;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('9cbcc943-3f31-573a-b74c-a31a76754940','b773f033-c4f0-5f75-982b-261cec99d02c','<div>',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('137f0c14-510c-589e-a52f-ee0f4c70c3aa','b773f033-c4f0-5f75-982b-261cec99d02c','<h1>',true) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('22b99d69-1a5a-50f8-9613-461fca676fc9','b773f033-c4f0-5f75-982b-261cec99d02c','<footer>',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_questions(id,lesson_id,prompt,position) values ('f23237e3-c399-51fa-a351-ca94f79a6915','6fe2ba86-82e8-577f-9340-283455b3f2b5','¿Para qué sirve HTML?',2) on conflict(id) do update set prompt=excluded.prompt;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('b46f3cc4-292c-58bc-8d2f-1e8d1e7fa8b0','f23237e3-c399-51fa-a351-ca94f79a6915','Para estructurar contenido',true) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('68a6a22d-ae08-5d2a-995b-a7e5180ddbef','f23237e3-c399-51fa-a351-ca94f79a6915','Para editar fotos',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('8701fce4-a359-578c-a131-ac3a4bb11d5f','f23237e3-c399-51fa-a351-ca94f79a6915','Para configurar servidores',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_lessons(id,module_id,title,description,position,video_asset,duration_minutes,is_preview) values ('4051e85b-bb17-5840-b82a-1d9f04242128','ad9abdd1-350e-509d-928d-dbb8f9abaf27','CSS: diseño y estilos','Comprende selectores, propiedades, color y técnicas para crear interfaces responsive.',2,'assets/videos/02_css.mp4',1,false) on conflict (id) do update set title=excluded.title, description=excluded.description,video_asset=excluded.video_asset;

insert into public.mobile_quiz_questions(id,lesson_id,prompt,position) values ('ab6002b5-df0b-5bd1-ac9f-bf352172a5b7','4051e85b-bb17-5840-b82a-1d9f04242128','¿Qué tecnología define los estilos visuales?',1) on conflict(id) do update set prompt=excluded.prompt;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('0279dff9-86fb-5e7c-aa21-31dbdf15a5df','ab6002b5-df0b-5bd1-ac9f-bf352172a5b7','PostgreSQL',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('26cbb7c7-d241-5692-95da-df9d6743f4fe','ab6002b5-df0b-5bd1-ac9f-bf352172a5b7','CSS',true) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('f07d9633-dbf7-577d-9727-cecdec31e253','ab6002b5-df0b-5bd1-ac9f-bf352172a5b7','Git',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_questions(id,lesson_id,prompt,position) values ('edf237c9-5e3f-5ac4-983a-86adeb2a07af','4051e85b-bb17-5840-b82a-1d9f04242128','¿Qué propiedad sirve para cambiar el color de un texto?',2) on conflict(id) do update set prompt=excluded.prompt;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('44108fae-4e83-5b45-9383-306fdb2068b5','edf237c9-5e3f-5ac4-983a-86adeb2a07af','color',true) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('f0fcdba2-11b7-50ad-b0be-0c350d78dc30','edf237c9-5e3f-5ac4-983a-86adeb2a07af','font-server',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('0833c456-0913-55a3-bf4d-b0607f02f51d','edf237c9-5e3f-5ac4-983a-86adeb2a07af','main',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_lessons(id,module_id,title,description,position,video_asset,duration_minutes,is_preview) values ('e92e513d-b1e8-5cdd-849e-c65f44be062b','ad9abdd1-350e-509d-928d-dbb8f9abaf27','JavaScript: interactividad','Descubre eventos, variables y actualización del contenido al interactuar con la página.',3,'assets/videos/03_javascript.mp4',1,false) on conflict (id) do update set title=excluded.title, description=excluded.description,video_asset=excluded.video_asset;

insert into public.mobile_quiz_questions(id,lesson_id,prompt,position) values ('1e895423-c043-5978-9ecd-be4345abf7d8','e92e513d-b1e8-5cdd-849e-c65f44be062b','¿Qué evento se utiliza frecuentemente al pulsar un botón?',1) on conflict(id) do update set prompt=excluded.prompt;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('00048be6-13a1-5032-89aa-4a8004e30fc8','1e895423-c043-5978-9ecd-be4345abf7d8','click',true) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('882ab874-bfc2-5e37-9ca8-3b1c0a1c3892','1e895423-c043-5978-9ecd-be4345abf7d8','compile',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('63f2f4d4-a67f-5131-b9b4-5baef4435f28','1e895423-c043-5978-9ecd-be4345abf7d8','load-css',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_questions(id,lesson_id,prompt,position) values ('2bae02d4-c3c1-5e51-b72a-a4c369a53d06','e92e513d-b1e8-5cdd-849e-c65f44be062b','¿Qué permite hacer JavaScript en una página?',2) on conflict(id) do update set prompt=excluded.prompt;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('45b3bed8-2baa-5dbd-90cc-13a019c7294a','2bae02d4-c3c1-5e51-b72a-a4c369a53d06','Responder a acciones del usuario',true) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('eb1f0c24-9fb5-56cd-85a4-e74c9b173c82','2bae02d4-c3c1-5e51-b72a-a4c369a53d06','Cambiar la memoria RAM',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;

insert into public.mobile_quiz_options(id,question_id,label,is_correct) values ('c34d5a49-46fa-5176-9128-a3ba7b53bfa4','2bae02d4-c3c1-5e51-b72a-a4c369a53d06','Instalar Android',false) on conflict(id) do update set label=excluded.label,is_correct=excluded.is_correct;
