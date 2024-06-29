  WITH cte AS (
--
--
--  Revisão |   Data   |   Autor   |    Observação
--        0 | 01/10/23 | Davi F.   | Criação
--        1 | 01/11/23 | Davi F.   | Inclusão do valor de frete rateado pelos itens presentes em notas de cond_frete CIF
--        2 | 01/01/24 | Davi F.   | Inclusão do número das notas fiscais de venda para os registros de notas fiscais de devolução 
--        3 | 20/02/24 | Davi F.   | Inclusão do número do pedido de venda de cada nota fiscal
--  
--

    --Seleciona as notas fiscais cujos eventos são de venda ou devolução de venda
        SELECT
            a.nota_fiscal,
            a.data_emissao,
            a.cod_evento,
            d.pedido                                                           pedido_venda,
            a.cod_cliente,
            b.sku_produto,
            b.unid_medida                                                      unid,
        --Torna negativa as quantidades de notas fiscais de devolução
            decode(c.operacao, 'D', b.quantidade *(- 1), b.quantidade)         quantidade,
            b.quantidade                                                       qtd_2,
        --Torna negativo o valor unitário de notas fiscais de devolução
            decode(c.operacao, 'D', b.preco_unitario *(- 1), b.preco_unitario) preco_unitario,
            b.preco_total,
            a.cond_frete
        FROM
                 nota_fiscal a
            JOIN item_nota_fiscal   b ON a.nota_fiscal = b.nota_fiscal
            JOIN evento             c ON a.cod_evento = c.evento
            LEFT JOIN pedido_nota_fiscal d ON a.nota_fiscal = d.nota_fiscal
        WHERE
                a.cancelada = 'N'
            AND c.operacao IN ( 'F', 'D' )
    )
--
--Revisão 1: Calcula o percentual de frete para as notas fiscais cujo tipo de frete é CIF
    , cte1 AS (
        SELECT
            a.nf_origem,
            sq.perc_frete
        FROM
            doc_associado_nf a,
            (
            --Seleciona os conhecimentos de frete associado às notas da 1ª CTE 
                SELECT
                    a.nf_associada                        conh_transp,
                --Calcula o percentual de frete tomando como base o valor do frete e o valor total de cada item
                    ( AVG(a.valor) / SUM(b.preco_total) ) perc_frete
                FROM
                    doc_associado_nf a,
                    cte              b
                WHERE
                        a.nf_origem = b.nota_fiscal
                    AND b.cond_frete = 'CIF'
                    AND a.tipo = 'F'
                GROUP BY
                    a.nf_associada
            )                sq
        WHERE
            a.nf_associada = sq.conh_transp
    )
--
--Revisão 2: Seleciona o número das notas fiscais de venda, bem como os pedidos de venda para aquelas notas que foram devolvidas 
    , cte2 AS (
        SELECT
            a.nf_origem    nf_devol,
            a.nf_associada nf_origem_dev,
            b.pedido       pedido_venda
        FROM
            doc_associado_nf   a
            LEFT JOIN pedido_nota_fiscal b ON a.nf_associada = b.nota_fiscal
        WHERE
                a.tipo = 'D'
            AND EXISTS (
                SELECT
                    1
                FROM
                    cte b
                WHERE
                    a.nf_origem = b.nota_fiscal
            )
    )
--
--Consolida as CTE extraídas
    SELECT
        a.nota_fiscal,
        a.data_emissao,
        a.cod_evento,
        nvl(a.pedido_venda, c.pedido_venda)                  pedido_venda,
        a.cod_cliente,
        a.sku_produto,
        a.unid,
        a.quantidade,
        a.preco_unitario,
        a.cond_frete,
    --Gera o custo de frete unitário para cada item presente em notas de tipo CIF
        round(((a.preco_total / a.qtd_2) * b.perc_frete), 4) custo_frete_unit,
        c.nf_origem_dev
    FROM
        cte  a
        LEFT JOIN cte1 b ON a.nota_fiscal = b.nf_origem
        LEFT JOIN cte2 c ON a.nota_fiscal = c.nf_devol
    ORDER BY
        2;
