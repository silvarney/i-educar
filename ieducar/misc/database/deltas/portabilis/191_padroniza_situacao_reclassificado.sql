--
-- @author   Gabriel Matos de Souza <gabriel@portabilis.com.br>
-- @license  @@license@@
-- @version  $Id$

update relatorio.matricula_situacao set cod_situacao = 5 where cod_situacao = 7;

CREATE OR REPLACE VIEW relatorio.view_situacao AS
    SELECT matricula.cod_matricula,
       situacao_matricula.cod_situacao,
       matricula_turma.ref_cod_turma AS cod_turma,
       matricula_turma.sequencial,

  (SELECT CASE
              WHEN matricula_turma.remanejado THEN 'Remanejado'::character varying
              WHEN matricula_turma.transferido THEN 'Transferido'::character varying
              WHEN matricula_turma.reclassificado THEN 'Reclassificado'::character varying
              WHEN matricula_turma.abandono THEN
                     (SELECT COALESCE(abandono_tipo.nome, 'Abandono'::character varying) AS "coalesce"
                      FROM pmieducar.abandono_tipo
                      WHERE matricula.ref_cod_abandono_tipo = abandono_tipo.cod_abandono_tipo
                        AND abandono_tipo.ativo = 1 LIMIT 1)
              WHEN matricula.aprovado = 1 THEN 'Aprovado'::character varying
              WHEN matricula.aprovado = 12 THEN 'Aprovado com dependência'::character varying
              WHEN matricula.aprovado = 2 THEN 'Reprovado'::character varying
              WHEN matricula.aprovado = 3 THEN 'Andamento'::character varying
              WHEN matricula.aprovado = 4 THEN 'Transferido'::character varying
              WHEN matricula.aprovado = 5 THEN 'Reclassificado'::character varying
              WHEN matricula.aprovado = 6 THEN
                     (SELECT COALESCE(abandono_tipo.nome, 'Abandono'::character varying) AS "coalesce"
                      FROM pmieducar.abandono_tipo
                      WHERE matricula.ref_cod_abandono_tipo = abandono_tipo.cod_abandono_tipo
                        AND abandono_tipo.ativo = 1 LIMIT 1)
              ELSE 'Recl'::character varying
          END AS "case") AS texto_situacao,

  (SELECT CASE
              WHEN matricula_turma.remanejado THEN 'Rem'::character varying
              WHEN matricula_turma.transferido THEN 'Trs'::character varying
              WHEN matricula_turma.reclassificado THEN 'Recl'::character varying
              WHEN matricula_turma.abandono THEN
                     (SELECT COALESCE(abandono_tipo.nome, 'Aba'::character varying) AS "coalesce"
                      FROM pmieducar.abandono_tipo
                      WHERE matricula.ref_cod_abandono_tipo = abandono_tipo.cod_abandono_tipo
                        AND abandono_tipo.ativo = 1 LIMIT 1)
              WHEN matricula.aprovado = 1 THEN 'Apr'::character varying
              WHEN matricula.aprovado = 12 THEN 'ApDp'::character varying
              WHEN matricula.aprovado = 2 THEN 'Rep'::character varying
              WHEN matricula.aprovado = 3 THEN 'And'::character varying
              WHEN matricula.aprovado = 4 THEN 'Trs'::character varying
              WHEN matricula.aprovado = 5 THEN 'Recl'::character varying
              WHEN matricula.aprovado = 6 THEN
                     (SELECT COALESCE(abandono_tipo.nome, 'Aba'::character varying) AS "coalesce"
                      FROM pmieducar.abandono_tipo
                      WHERE matricula.ref_cod_abandono_tipo = abandono_tipo.cod_abandono_tipo
                        AND abandono_tipo.ativo = 1 LIMIT 1)
              ELSE 'Recl'::character varying
          END AS "case") AS texto_situacao_simplificado
FROM relatorio.situacao_matricula,
     pmieducar.matricula
LEFT JOIN pmieducar.matricula_turma ON matricula_turma.ref_cod_matricula = matricula.cod_matricula
WHERE CASE
          WHEN matricula.aprovado = 4 THEN matricula_turma.ativo = 1
               OR (EXISTS
                     (SELECT 1
                      FROM pmieducar.transferencia_solicitacao
                      WHERE transferencia_solicitacao.ref_cod_matricula_saida = matricula.cod_matricula
                        AND transferencia_solicitacao.ativo = 1 LIMIT 1))
               OR matricula_turma.transferido
               OR matricula_turma.reclassificado
          WHEN matricula.aprovado = 6 THEN matricula_turma.ativo = 1
               OR matricula_turma.abandono
          WHEN matricula.aprovado = 5 THEN matricula_turma.ativo = 1
               OR matricula_turma.reclassificado
          ELSE matricula_turma.ativo = 1
               OR matricula_turma.abandono
               OR matricula_turma.reclassificado
               OR matricula_turma.transferido
               OR matricula_turma.remanejado
      END
  AND CASE
          WHEN situacao_matricula.cod_situacao = 10 THEN matricula.aprovado = ANY (ARRAY[1::smallint, 2::smallint, 3::smallint, 4::smallint, 5::smallint, 6::smallint, 12::smallint])
          WHEN situacao_matricula.cod_situacao = 9 THEN (matricula.aprovado = ANY (ARRAY[1::smallint, 2::smallint, 3::smallint, 5::smallint, 12::smallint]))
               AND (NOT matricula_turma.reclassificado
                    OR matricula_turma.reclassificado IS NULL)
               AND (NOT matricula_turma.abandono
                    OR matricula_turma.abandono IS NULL)
               AND (NOT matricula_turma.remanejado
                    OR matricula_turma.remanejado IS NULL)
               AND (NOT matricula_turma.transferido
                    OR matricula_turma.transferido IS NULL)
          WHEN situacao_matricula.cod_situacao = ANY (ARRAY[1, 2, 3, 12]) THEN matricula.aprovado = situacao_matricula.cod_situacao
               AND (NOT matricula_turma.reclassificado
                    OR matricula_turma.reclassificado IS NULL)
               AND (NOT matricula_turma.abandono
                    OR matricula_turma.abandono IS NULL)
               AND (NOT matricula_turma.remanejado
                    OR matricula_turma.remanejado IS NULL)
               AND (NOT matricula_turma.transferido
                    OR matricula_turma.transferido IS NULL)
          ELSE matricula.aprovado = situacao_matricula.cod_situacao
      END
  AND matricula_turma.sequencial = (
                                      (SELECT max(mt.sequencial) AS MAX
                                       FROM pmieducar.matricula_turma mt
                                       WHERE mt.ref_cod_matricula = matricula.cod_matricula
                                         AND mt.ref_cod_turma = matricula_turma.ref_cod_turma));



  -- undo

update relatorio.matricula_situacao set cod_situacao = 7 where cod_situacao = 5;

CREATE OR REPLACE VIEW relatorio.view_situacao AS
    SELECT matricula.cod_matricula,
       situacao_matricula.cod_situacao,
       matricula_turma.ref_cod_turma AS cod_turma,
       matricula_turma.sequencial,

  (SELECT CASE
              WHEN matricula_turma.remanejado THEN 'Remanejado'::character varying
              WHEN matricula_turma.transferido THEN 'Transferido'::character varying
              WHEN matricula_turma.reclassificado THEN 'Recuperação'::character varying
              WHEN matricula_turma.abandono THEN
                     (SELECT COALESCE(abandono_tipo.nome, 'Abandono'::character varying) AS "coalesce"
                      FROM pmieducar.abandono_tipo
                      WHERE matricula.ref_cod_abandono_tipo = abandono_tipo.cod_abandono_tipo
                        AND abandono_tipo.ativo = 1 LIMIT 1)
              WHEN matricula.aprovado = 1 THEN 'Aprovado'::character varying
              WHEN matricula.aprovado = 12 THEN 'Aprovado com dependência'::character varying
              WHEN matricula.aprovado = 2 THEN 'Reprovado'::character varying
              WHEN matricula.aprovado = 3 THEN 'Andamento'::character varying
              WHEN matricula.aprovado = 4 THEN 'Transferido'::character varying
              WHEN matricula.aprovado = 5 THEN 'Reclassificado'::character varying
              WHEN matricula.aprovado = 6 THEN
                     (SELECT COALESCE(abandono_tipo.nome, 'Abandono'::character varying) AS "coalesce"
                      FROM pmieducar.abandono_tipo
                      WHERE matricula.ref_cod_abandono_tipo = abandono_tipo.cod_abandono_tipo
                        AND abandono_tipo.ativo = 1 LIMIT 1)
              ELSE 'Rec'::character varying
          END AS "case") AS texto_situacao,

  (SELECT CASE
              WHEN matricula_turma.remanejado THEN 'Rem'::character varying
              WHEN matricula_turma.transferido THEN 'Trs'::character varying
              WHEN matricula_turma.reclassificado THEN 'Rec'::character varying
              WHEN matricula_turma.abandono THEN
                     (SELECT COALESCE(abandono_tipo.nome, 'Aba'::character varying) AS "coalesce"
                      FROM pmieducar.abandono_tipo
                      WHERE matricula.ref_cod_abandono_tipo = abandono_tipo.cod_abandono_tipo
                        AND abandono_tipo.ativo = 1 LIMIT 1)
              WHEN matricula.aprovado = 1 THEN 'Apr'::character varying
              WHEN matricula.aprovado = 12 THEN 'ApDp'::character varying
              WHEN matricula.aprovado = 2 THEN 'Rep'::character varying
              WHEN matricula.aprovado = 3 THEN 'And'::character varying
              WHEN matricula.aprovado = 4 THEN 'Trs'::character varying
              WHEN matricula.aprovado = 5 THEN 'Recl'::character varying
              WHEN matricula.aprovado = 6 THEN
                     (SELECT COALESCE(abandono_tipo.nome, 'Aba'::character varying) AS "coalesce"
                      FROM pmieducar.abandono_tipo
                      WHERE matricula.ref_cod_abandono_tipo = abandono_tipo.cod_abandono_tipo
                        AND abandono_tipo.ativo = 1 LIMIT 1)
              ELSE 'Rec'::character varying
          END AS "case") AS texto_situacao_simplificado
FROM relatorio.situacao_matricula,
     pmieducar.matricula
LEFT JOIN pmieducar.matricula_turma ON matricula_turma.ref_cod_matricula = matricula.cod_matricula
WHERE CASE
          WHEN matricula.aprovado = 4 THEN matricula_turma.ativo = 1
               OR (EXISTS
                     (SELECT 1
                      FROM pmieducar.transferencia_solicitacao
                      WHERE transferencia_solicitacao.ref_cod_matricula_saida = matricula.cod_matricula
                        AND transferencia_solicitacao.ativo = 1 LIMIT 1))
               OR matricula_turma.transferido
               OR matricula_turma.reclassificado
          WHEN matricula.aprovado = 6 THEN matricula_turma.ativo = 1
               OR matricula_turma.abandono
          WHEN matricula.aprovado = 5 THEN matricula_turma.ativo = 1
               OR matricula_turma.abandono
          ELSE matricula_turma.ativo = 1
               OR matricula_turma.abandono
               OR matricula_turma.reclassificado
               OR matricula_turma.transferido
               OR matricula_turma.remanejado
      END
  AND CASE
          WHEN situacao_matricula.cod_situacao = 10 THEN matricula.aprovado = ANY (ARRAY[1::smallint, 2::smallint, 3::smallint, 4::smallint, 5::smallint, 6::smallint, 12::smallint])
          WHEN situacao_matricula.cod_situacao = 7 THEN matricula.aprovado = 5::smallint
          WHEN situacao_matricula.cod_situacao = 9 THEN (matricula.aprovado = ANY (ARRAY[1::smallint, 2::smallint, 3::smallint, 5::smallint, 12::smallint]))
               AND (NOT matricula_turma.reclassificado
                    OR matricula_turma.reclassificado IS NULL)
               AND (NOT matricula_turma.abandono
                    OR matricula_turma.abandono IS NULL)
               AND (NOT matricula_turma.remanejado
                    OR matricula_turma.remanejado IS NULL)
               AND (NOT matricula_turma.transferido
                    OR matricula_turma.transferido IS NULL)
          WHEN situacao_matricula.cod_situacao = ANY (ARRAY[1, 2, 3, 12]) THEN matricula.aprovado = situacao_matricula.cod_situacao
               AND (NOT matricula_turma.reclassificado
                    OR matricula_turma.reclassificado IS NULL)
               AND (NOT matricula_turma.abandono
                    OR matricula_turma.abandono IS NULL)
               AND (NOT matricula_turma.remanejado
                    OR matricula_turma.remanejado IS NULL)
               AND (NOT matricula_turma.transferido
                    OR matricula_turma.transferido IS NULL)
          ELSE matricula.aprovado = situacao_matricula.cod_situacao
      END
  AND matricula_turma.sequencial = (
                                      (SELECT max(mt.sequencial) AS MAX
                                       FROM pmieducar.matricula_turma mt
                                       WHERE mt.ref_cod_matricula = matricula.cod_matricula
                                         AND mt.ref_cod_turma = matricula_turma.ref_cod_turma));
