/* Inscritos aplica para saber que el usuario se encuentra inscrito al curso*/
select * --case when count(*) > 0 then 1 else 0 end
	FROM mdl_course a --Cursos principal
	JOIN public.mdl_course_config b ON b.course=a.id --Configuración de cursos
	JOIN public.mdl_course_categories c ON c.id = a.category
	JOIN mdl_context d ON d.instanceid = a.id --Contexto 
	JOIN mdl_role_assignments e ON e.contextid = d.id  --Enrolamiento del curso 
	--JOIN mdl_role ON mdl_role.id = mdl_role_assignments.roleid
	JOIN mdl_user f ON f.id = e.userid --relacion del usuario al enrolamiento 
		where e.roleid in(5) --Para obtener unicamente información de alumnos
;

/* Informacion de usuarios 2016 */
select --62.251s
	to_char(to_timestamp(c.startdate),'yyyy'),c.id id_curso, c.shortname,  
	c.fullname nombre_curso, DATE(to_timestamp(c.startdate)) f_inicio, cfg.lastdate f_fin,
	u.id id_user, u.username matricula, sgpu.nom_nombre, sgpu.nom_paterno, sgpu.nom_materno,
	u.cat id_categoria_moodle, B.des_clave cve_categoria_moodle, B.nom_nombre categoria_moodle, -- Agregados para auditoria
	u.cve_departamental cve_dep_adscr_moodle, D.nom_depto_adscripcion nom_depto_adscr_moodle ,-- Agregados para auditoria
	dcp.code folio,case when dcp.code is not null then 'Aprobado' else 'No aprobado' end as aprobado
,D.cve_delegacion, D.nom_delegacion,
	D.cve_regiones, D.name_region, D.des_nivel_atencion,
(CASE WHEN D.cve_delegacion='15' or D.cve_delegacion='16' THEN 'ESTADO DE MEXICO'
        WHEN D.cve_delegacion='31' or D.cve_delegacion='32' THEN 'VERACRUZ'
        WHEN D.cve_delegacion='35' or D.cve_delegacion='36' or D.cve_delegacion='37' or D.cve_delegacion='38' THEN 'CIUDAD DE MEXICO'
        ELSE D.nom_delegacion
   	end) as ESTADO
,pcp.categoria_por_perfil, pcp.subcategoria
/*, case when (select count(*) from public.mdl_logstore_standard_log lh where lh.relateduserid is null and lh.contextinstanceid = c.id and lh.userid = u.id) > 0 then 1 
	else 0 end as accceso*/
from 
	public.mdl_user u --Usuarios 
	inner join mdl_user_enrolments ue on ue.userid = u.id --enrolamientos del usuario
	join gestion.sgp_tab_usuario sgpu on(u.username = sgpu.nom_usuario)
	inner join mdl_enrol e on e.id = ue.enrolid
	inner join mdl_role_assignments ra on ra.userid = u.id
	inner join mdl_context ct on ct.id = ra.contextid and ct.contextlevel = 50
	inner join mdl_course c on c.id = ct.instanceid and e.courseid = c.id
	INNER JOIN mdl_course_config cfg ON c.id = cfg.course
	LEFT JOIN nomina.ssn_categoria B on B.cve_categoria = u.cat -- solo 77,415 alumnos tienen categoria (Agregado para auditoria)
	LEFT JOIN departments.ssv_departamentos D on D.cve_depto_adscripcion = u.cve_departamental -- solo 118,780 alumnos tienen depto_adscr (Agregado para auditoria)
	left join public.mdl_certificate cer on (cer.course = c.id)
	left join public.mdl_certificate_issues dcp on cer.id = dcp.certificateid and dcp.userid = u.id
	left join catalogos.perfil_cores pcp on pcp.clave_categoria = B.des_clave
where 
	ra.roleid in(5) 
	and to_char(to_timestamp(c.startdate),'yyyy') = '2016'
order by 1,shortname
;


/* catalogo de perfiles cores  vista */
CREATE OR REPLACE VIEW catalogos.perfil_cores AS
 SELECT perfiles.categoria_por_perfil,
    perfiles.subcategoria,
    perfiles.clave_categoria
   FROM catalogos.dblink('dbname=cores_junio_18 host=11.32.41.13 user=innovaedu password=innovaedu'::text, 'select "categoria_por_perfil", "subcategoria", "clave_categoria"  from catalogos.categorias cat'::text) perfiles(categoria_por_perfil character varying, subcategoria character varying, clave_categoria character varying);
   
/*Obtención de certificados para años anteriores al 2018*/
select	D.userid, C.course curso_id, D.code certificados
	from public.mdl_certificate C --Información de certificado con el curso
	left join public.mdl_certificate_issues D on C.id = D.certificateid --Relacion certificado con el usuario 

/*Obtención de certificados para años de 2018 en adelante*/
select c.userid, a.course curso_id, b.code certificados
	from public.mdl_customcert a -- tabla a actualizar si existe el certificado para el curs
	join public.mdl_customcert_issues b on b.customcertid = a.id --Transistiva de certificado
	join cert.ssc_tab_cert_issues_conf c on c.cert_issues_id = b.id--Relaciona al usuario 

/* Perfiles por categorias */
select "categoria_por_perfil", "subcategoria", "clave_categoria"  from catalogos.categorias cat 	

