### Objetivos do projeto

Permitir a integração e o armazenamento de informações relativas ao faturamento de uma organização do ramo atacadista de bens domésticos, cujos dados são oriundos de diversas fontes. Sendo assim, faz-se necessário um único local de armazenamento para esses dados (na figura de um data warehouse), o qual será, portanto, a fonte única da verdade. Além do mais, esta arquitetura facilitará imensamente a geração de relatórios, bem como a alimentação de modelos de machine learning. 
As referidas fontes dos dados são:

- Banco de Dados On-Premisse da Oracle;
- Arquivos CSV;
- Arquivos Excel;
- APIs.

### Serviços utilizados

Para tal objetivo, utilizei 4 serviços em nuvem pertencentes à plataforma Azure. São eles:

- Azure Data Factory: para a ingestão e a orquestração dos pipelines de dados;
- Azure Data Lake: para a área de stagging;
- Azure SQL Server: para a formação do data warehouse;
- Azure Key Vault: para armazenar as credenciais de acessos aos demais serviços.

### Fluxograma de execução

![image](https://github.com/davifpereira/portfolio-adf1/assets/144074745/6a988b9a-f24f-4f2d-b21d-09d534d6ebca)

Observações:
- A maioria das estruturas de dados passam pela área de stagging, mas há aquelas que são carregados diretamente no DW, pois são simples cópias de dados;
- No Azure Data Factory são utilizados data flows tanto para combinar dados de diferentes fontes quanto para aplicar SCD (Slowly Changing Dimension) de tipo II em algumas tabelas.

### Modelagem lógica do data warehouse

![image](https://github.com/davifpereira/portfolio-adf1/assets/144074745/c313d153-5e51-42e0-9ae6-7120f7804170)
