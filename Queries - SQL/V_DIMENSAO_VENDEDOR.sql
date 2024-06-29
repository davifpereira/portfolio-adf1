  WITH cte AS (
--
--
--  Revisão |   Data   |   Autor   |    Observação
--       0  | 01/10/23 | Davi F.   | Criação
--       1  | 01/01/24 | Davi F.   | Acréscimo de mais dois níveis hierárquicos 
--  
--  
        --Baseado na relação de vendedores e seus superiores, monta uma tabela contendo o organograma comercial
        SELECT
            a.cod_vendedor,
            LEVEL nvl_hierq,
            --Concatena o código do vendedor e os seus superiores (se existirem)
            sys_connect_by_path(a.cod_vendedor, '|') path
        FROM
            vendedor a
        CONNECT BY
            PRIOR a.cod_vendedor = a.cod_superior
    )
    --
    --Cria colunas para organizar os níveis hierárquicos        
    , cte1 AS (
        SELECT
            a.cod_vendedor,
            --Retorna o nível hierárquivo máximo geral 
            MAX(a.nvl_hierq) OVER() max_nivel_h,
            --Usa expressão regular para desconcatenar a hierárquia vendedor X superiores
            regexp_substr(a.path, '[^|]+', 1, 1) cod_sup_1,
            regexp_substr(a.path, '[^|]+', 1, 2) cod_sup_2,
            regexp_substr(a.path, '[^|]+', 1, 3) cod_sup_3,
            --Revisão 1
            regexp_substr(a.path, '[^|]+', 1, 4) cod_sup_4,
            --Revisão 1
            regexp_substr(a.path, '[^|]+', 1, 5) cod_sup_5
        FROM
            cte a,
            --Esta subquery apenas realiza um group by para verificar qual é o verdadeiro nível hierárquico de cada vendedor, 
            --pois a 1ª CTE retorna retorna o mesmo vendedor para cada nível hierárquico
            (
            select 
                cte.cod_vendedor,
                max(cte.nvl_hierq) nvl_hierq
            from cte
            group by
                cte.cod_vendedor
            ) sq
        WHERE
            a.cod_vendedor = sq.cod_vendedor
            and a.nvl_hierq = sq.nvl_hierq

    )
    --
    --Preenche as colunas relativas aos níveis hierárquicos até a coluna que representa o maior nível
    , cte2 AS (
        SELECT
            cte1.cod_vendedor,
            TO_NUMBER(cte1.cod_sup_1) cod_sup_1,
            CASE
                WHEN cte1.max_nivel_h >= 2 THEN
                    TO_NUMBER(coalesce(cte1.cod_sup_2, cte1.cod_sup_1))
                ELSE
                    NULL
            END                       cod_sup_2,
            CASE
                WHEN cte1.max_nivel_h >= 3 THEN
                    TO_NUMBER(coalesce(cte1.cod_sup_3, cte1.cod_sup_2, cte1.cod_sup_1))
                ELSE
                    NULL
            END                       cod_sup_3,
            CASE
                WHEN cte1.max_nivel_h >= 4 THEN
                    TO_NUMBER(coalesce(cte1.cod_sup_4, cte1.cod_sup_3, cte1.cod_sup_2, cte1.cod_sup_1))
                ELSE
                    NULL
            END                       cod_sup_4,
            CASE
                WHEN cte1.max_nivel_h >= 5 THEN
                    TO_NUMBER(coalesce(cte1.cod_sup_5, cte1.cod_sup_4, cte1.cod_sup_3, cte1.cod_sup_2, cte1.cod_sup_1))
                ELSE
                    NULL
            END                       cod_sup_5
        FROM
            cte1
    )
    --
    --Cria uma tabela contendo o código do vendedor e o seu nome completo
    , cte3 AS (
        SELECT
            cod_vendedor,
            concat(nome || ' ', sobrenome) nome_completo
        FROM
            vendedor
    )
    --
    --Baseado na tabela da última CTE, para cada nível hierárquico, traz o nome completo do vendedor/superior 
    , cte4 AS (
        SELECT
            a.cod_vendedor,
            a.cod_sup_1,
            b.nome_completo nome_comp_1,
            a.cod_sup_2,
            c.nome_completo nome_comp_2,
            a.cod_sup_3,
            d.nome_completo nome_comp_3,
            a.cod_sup_4,
            e.nome_completo nome_comp_4,
            a.cod_sup_5,
            f.nome_completo nome_comp_5
        FROM
                 cte2 a
            INNER JOIN cte3 b ON a.cod_sup_1 = b.cod_vendedor
            LEFT JOIN cte3 c ON a.cod_sup_2 = c.cod_vendedor
            LEFT JOIN cte3 d ON a.cod_sup_3 = d.cod_vendedor
            LEFT JOIN cte3 e ON a.cod_sup_4 = e.cod_vendedor
            LEFT JOIN cte3 f ON a.cod_sup_5 = f.cod_vendedor
    )
    --
    --Monta a query completa da futura tabela dimensão
    SELECT
        a.cod_vendedor,
        concat(a.nome || ' ', a.sobrenome) nome_completo,
        b.cargo,
        c.descricao                        regiao_venda,
        a.cidade_atuacao,
        d.cod_sup_1,
        d.nome_comp_1,
        d.cod_sup_2,
        d.nome_comp_2,
        d.cod_sup_3,
        d.nome_comp_3,
        d.cod_sup_4,
        d.nome_comp_4,
        d.cod_sup_5,
        d.nome_comp_5
    FROM
             vendedor a
        INNER JOIN cargo_salarios b ON a.cod_cargo = b.cod_cargo
        LEFT JOIN regiao_venda   c ON a.cod_regiao = c.cod_regiao
        INNER JOIN cte4           d ON a.cod_vendedor = d.cod_vendedor;
