-- Type: op_status

-- DROP TYPE IF EXISTS public.op_status;

CREATE TYPE public.op_status AS ENUM
    ('PENDING', 'PARSE', 'PARSING', 'PARSED', 'FAILED', 'IMPORTED', 'CHECKED', 'ERROR');

ALTER TYPE public.op_status
    OWNER TO egs_pguser;
	


-- Table: public.bank_report

-- DROP TABLE IF EXISTS public.bank_report;

CREATE TABLE IF NOT EXISTS public.bank_report
(
    id bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    description text COLLATE pg_catalog."default",
    CONSTRAINT pk_bank_report PRIMARY KEY (id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.bank_report
    OWNER to egs_pguser;
	

-- Table: public.report_to_import

-- DROP TABLE IF EXISTS public.report_to_import;

CREATE TABLE IF NOT EXISTS public.report_to_import
(
    id bigint NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    bank_account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    bank_report_id bigint NOT NULL,
    upload_date date NOT NULL,
    file_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    report_status op_status NOT NULL DEFAULT 'PARSE'::op_status,
    CONSTRAINT pk_report_to_import PRIMARY KEY (id),
    CONSTRAINT fk_report_to_import_bank_account FOREIGN KEY (bank_account_id)
        REFERENCES public.bank_account (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_report_to_import_bank_report FOREIGN KEY (bank_report_id)
        REFERENCES public.bank_report (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_report_to_import_natural_person FOREIGN KEY (user_id)
        REFERENCES public.natural_person (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.report_to_import
    OWNER to egs_pguser;




-- View: public.vw_report_to_import

-- DROP VIEW public.vw_report_to_import;

CREATE OR REPLACE VIEW public.vw_report_to_import
 AS
 SELECT report_to_import.id,
    investors.person_name AS investidor,
    institutions.person_name AS banco,
    bank_account.account_number AS conta,
    bank_report.name AS tipo,
    report_to_import.file_name AS arquivo,
    report_to_import.upload_date AS data_upload,
    users.identification AS usuario,
    concat(report_to_import.start_date, ' a ', report_to_import.end_date) AS periodo,
    report_to_import.report_status AS status
   FROM report_to_import
     LEFT JOIN bank_account ON report_to_import.bank_account_id = bank_account.id
     LEFT JOIN legal_person institutions ON bank_account.institution_id = institutions.id
     LEFT JOIN person investors ON bank_account.person_id = investors.id AND investors.labels @> '{INVESTIDOR}'::text[]
     LEFT JOIN person users ON report_to_import.user_id = users.id AND users.labels @> '{USUÁRIO}'::text[]
     LEFT JOIN bank_report ON report_to_import.bank_report_id = bank_report.id
  ORDER BY report_to_import.id DESC;

ALTER TABLE public.vw_report_to_import
    OWNER TO egs_pguser;




INSERT INTO public.bank_report (name, description) VALUES ('Movimentos', 'Relatórios de transações cotidianas.');
INSERT INTO public.bank_report (name, description) VALUES ('Posições', 'Relatórios para acompanhamento da carteira do investidor.');